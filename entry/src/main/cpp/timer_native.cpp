#include <napi/native_api.h>
// HarmonyOS N-API headers
#include <map>
#include <memory>
#include <mutex>
#include <thread>
#include <condition_variable>
#include <atomic>
#include <chrono>

namespace {
struct TimerTask {
    std::thread worker;
    std::atomic<bool> cancelled{false};
    std::mutex mtx;
    std::condition_variable cv;
    napi_threadsafe_function tsfn{nullptr};
    ~TimerTask() {
        // Ensure TSFN is released exactly once
        if (tsfn != nullptr) {
            napi_release_threadsafe_function(tsfn, napi_tsfn_release);
            tsfn = nullptr;
        }
    }
};

std::mutex g_mutex;
std::map<int64_t, std::shared_ptr<TimerTask>> g_tasks;
std::atomic<int64_t> g_nextId{1};

void TSFNCallJs(napi_env env, napi_value jsCallback, void * /*context*/, void * /*data*/) {
    if (!env || !jsCallback)
        return;
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    // callback()
    napi_call_function(env, undefined, jsCallback, 0, nullptr, nullptr);
}

napi_value SetTimeout(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    if (argc < 2) {
        napi_throw_type_error(env, nullptr, "setTimeout requires (function, delayMs)");
        return nullptr;
    }
    napi_valuetype cbType;
    napi_typeof(env, argv[0], &cbType);
    if (cbType != napi_function) {
        napi_throw_type_error(env, nullptr, "First argument must be function");
        return nullptr;
    }
    int64_t delayMs = 0;
    napi_get_value_int64(env, argv[1], &delayMs);
    if (delayMs < 0)
        delayMs = 0;

    // Create TSFN to safely invoke JS callback from worker thread
    napi_value asyncResourceName;
    napi_create_string_utf8(env, "tsfn", 4, &asyncResourceName);
    napi_threadsafe_function tsfn;
    auto r = napi_create_threadsafe_function(env,
                                             argv[0],           // js function
                                             nullptr,           // async_resource
                                             asyncResourceName, // resource_name
                                             0,                 // max_queue_size
                                             1,                 // initial_thread_count
                                             nullptr,           // thread_finalize_data
                                             nullptr,           // thread_finalize_cb
                                             nullptr,           // context
                                             TSFNCallJs,        // call_js_cb
                                             &tsfn);
    if (r != napi_ok) {
        napi_throw_type_error(env, nullptr, "napi_create_threadsafe_function failed");
        napi_value result;
        napi_create_int32(env, -1, &result);
        return result;
    }

    auto task = std::make_shared<TimerTask>();
    task->tsfn = tsfn;
    int64_t id = g_nextId.fetch_add(1);

    {
        std::scoped_lock lk(g_mutex);
        g_tasks.emplace(id, task);
    }

    // Start worker thread with condition_variable cancellation
    task->worker = std::thread([delayMs, id]() {
        std::shared_ptr<TimerTask> t;
        {
            std::scoped_lock lk(g_mutex);
            auto it = g_tasks.find(id);
            if (it == g_tasks.end()) {
                return;
            }
            t = it->second;
        }

        std::unique_lock<std::mutex> lk(t->mtx);
        if (!t->cv.wait_for(lk, std::chrono::milliseconds(delayMs), [&t]() { return t->cancelled.load(); })) {
            // timeout reached, not cancelled
        } else {
            // cancelled
            // Remove from map on cancel
            std::scoped_lock lk2(g_mutex);
            g_tasks.erase(id);
            return;
        }

        if (t->cancelled.load()) {
            // Remove from map
            std::scoped_lock lk2(g_mutex);
            g_tasks.erase(id);
            return;
        }

        // queue a call to JS
        napi_call_threadsafe_function(t->tsfn, nullptr, napi_tsfn_nonblocking);
        // Allow JS call to drain; release will be handled in destructor

        // Remove from map
        std::scoped_lock lk2(g_mutex);
        g_tasks.erase(id);
    });
    // Detach the worker thread to avoid needing to join from ClearTimeout
    task->worker.detach();

    napi_value result;
    napi_create_int64(env, id, &result);
    return result;
}

napi_value ClearTimeout(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    if (argc < 1) {
        napi_throw_type_error(env, nullptr, "clearTimeout requires (id)");
        return nullptr;
    }
    int64_t id = 0;
    napi_get_value_int64(env, argv[0], &id);
    std::shared_ptr<TimerTask> t;
    {
        std::scoped_lock lk(g_mutex);
        auto it = g_tasks.find(id);
        if (it != g_tasks.end()) {
            t = it->second;
            g_tasks.erase(it);
        }
    }
    if (t) {
        t->cancelled.store(true);
        t->cv.notify_all();
        // Do not erase map or release TSFN here; let worker thread handle cleanup
    }
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}
napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"setTimeout", 0, SetTimeout, 0, 0, 0, napi_default, 0},
        {"clearTimeout", 0, ClearTimeout, 0, 0, 0, napi_default, 0},
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
} // namespace

// Register module
NAPI_MODULE(timer_native, Init)
