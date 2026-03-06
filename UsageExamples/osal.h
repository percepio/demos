/* osal.h
 *
 * OS Abstraction Layer for demo apps (Zephyr + FreeRTOS)
 *
 * Features:
 *   - Threads/tasks: static create, sleep, delay-until, get tick count, delete self/other
 *   - Mutex: static create, take/give, optional delete (no-op for static)
 *   - Message queue: static create, send/receive, optional delete (no-op for static)
 *
 * RTOS selection:
 *   - If __ZEPHYR__ is defined (by Zephyr build system), use Zephyr.
 *   - Otherwise, assume FreeRTOS.
 *
 * Time base:
 *   - API uses milliseconds (ms) for sleeps/timeouts and OS_tick_t.
 *   - On Zephyr: OS_tick_t is ms since boot (k_uptime_get_32()).
 *   - On FreeRTOS: OS_tick_t is TickType_t from xTaskGetTickCount().
 *
 * FreeRTOS requirements:
 *   - configSUPPORT_STATIC_ALLOCATION == 1
 */

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef void (*OS_thread_fn_t)(void *arg);

/*
 * Start the scheduler (FreeRTOS) or do nothing (Zephyr).
 *
 * Rationale: keeps demo entry code identical across RTOSes.
 * - FreeRTOS: you must call vTaskStartScheduler() once tasks are created.
 * - Zephyr: the kernel is already running when application code executes.
 */
#if defined(__ZEPHYR__)
  #define OS_start_scheduler()   do { } while (0)
#else
  /* Declared later after including FreeRTOS headers. */
#endif

/* Special timeout value (ms) meaning "wait forever". */
#define OS_WAIT_FOREVER_MS  (0xFFFFFFFFu)

#if defined(__ZEPHYR__)

/* ============================== ZEPHYR ================================== */
#include <zephyr/kernel.h>

typedef k_tid_t    OS_thread_t;
typedef uint32_t   OS_tick_t;      /* ms since boot */

typedef struct k_mutex * OS_mutex_t;
typedef struct k_msgq  * OS_queue_t;

#define OS_PRIO_HIGHEST 0
#define OS_PRIO_HIGH 1
#define OS_PRIO_MID 2
#define OS_PRIO_LOW 3
#define OS_PRIO_LOWEST 4

#define OS_delay_ms(ms_)  do { k_sleep(K_MSEC((ms_))); } while (0)

static inline OS_tick_t OS_get_tick_count(void)
{
  return (OS_tick_t)k_uptime_get_32();
}

/* Drift-free, FreeRTOS-like delay-until (ms based). */
static inline void _old_OS_delay_until_ms(OS_tick_t *p_last_wake_ms, uint32_t period_ms)
{
  OS_tick_t next = (OS_tick_t)(*p_last_wake_ms + (OS_tick_t)period_ms);
  OS_tick_t now  = OS_get_tick_count();

  int32_t remaining = (int32_t)(next - now); /* handles wrap-around */

  if (remaining > 0) {
    k_sleep(K_MSEC((uint32_t)remaining));
  } else {
    k_yield();
  }

  *p_last_wake_ms = next;
}

static inline void OS_delay_until_ms(OS_tick_t *p_last_wake_ms, OS_tick_t period_ms)
{
    OS_tick_t now = OS_get_tick_count();
    OS_tick_t last = *p_last_wake_ms;
    OS_tick_t next = last + period_ms;

    /* signed diff handles wrap-around */
    int32_t remaining = (int32_t)(next - now);

    if (remaining >= 0) {
        k_sleep(K_MSEC((uint32_t)remaining));
        *p_last_wake_ms = next;
        return;
    }

    /* We are late. Catch up last_wake so next wake is in the future,
       without burning CPU in a yield loop. */
    
    /* How far behind are we? */
    OS_tick_t behind = (OS_tick_t)(now - last);

    /* Advance by N whole periods so that (last + N*period) <= now,
       then set last_wake to that scheduled point. Next call will sleep. */
    OS_tick_t periods = behind / period_ms + 1u;

    *p_last_wake_ms = (OS_tick_t)(last + periods * period_ms);    

    k_sleep(K_NO_WAIT);
}



/* --- Threads ------------------------------------------------------------- */
#define OS_THREAD_STORAGE(name_, stack_bytes_)                       \
  K_THREAD_STACK_DEFINE(name_##_stack, (stack_bytes_));              \
  static struct k_thread name_##_tcb;                                \
  static OS_thread_t name_##_handle = (OS_thread_t)0

/* Zephyr priority: lower number => higher priority. */
#define OS_thread_create(name_, entry_fn_, arg_, prio_)              \
  do {                                                               \
    name_##_handle = k_thread_create(                                \
        &name_##_tcb,                                                \
        name_##_stack,                                               \
        K_THREAD_STACK_SIZEOF(name_##_stack),                        \
        (k_thread_entry_t)(entry_fn_),                               \
        (void *)(arg_), NULL, NULL,                                  \
        (prio_), 0, K_NO_WAIT);                                      \
    k_thread_name_set(name_##_handle, #name_);                        \
  } while (0)

#define OS_thread_delete(handle_)   do { k_thread_abort((handle_)); } while (0)
#define OS_thread_delete_self()     do { k_thread_abort(k_current_get()); } while (0)

/* --- Mutex --------------------------------------------------------------- */
#define OS_MUTEX_STORAGE(name_)        \
  static struct k_mutex name_##_m;     \
  static OS_mutex_t name_##_handle = &name_##_m

#define OS_mutex_create(name_)         do { k_mutex_init(&name_##_m); } while (0)

static inline int OS_mutex_take_ms(OS_mutex_t m, uint32_t timeout_ms)
{
  k_timeout_t to = (timeout_ms == OS_WAIT_FOREVER_MS) ? K_FOREVER : K_MSEC(timeout_ms);
  return (k_mutex_lock(m, to) == 0) ? 1 : 0;
}

static inline void OS_mutex_give(OS_mutex_t m)
{
  (void)k_mutex_unlock(m);
}

/* Static objects: delete is a no-op (kept for symmetry). */
static inline void OS_mutex_delete(OS_mutex_t m) { (void)m; }

/* --- Message queue ------------------------------------------------------- */
#define OS_QUEUE_STORAGE(name_, msg_size_, msg_count_)                           \
  static struct k_msgq name_##_q;                                                \
  static uint8_t name_##_q_buf[(msg_size_) * (msg_count_)];                      \
  static OS_queue_t name_##_handle = &name_##_q;                                 \
  enum { name_##_msg_size = (msg_size_), name_##_msg_count = (msg_count_) }

#define OS_queue_create(name_)                                                   \
  do {                                                                            \
    k_msgq_init(&name_##_q, name_##_q_buf, (name_##_msg_size), (name_##_msg_count)); \
  } while (0)

static inline int OS_queue_send_ms(OS_queue_t q, const void *p_msg, uint32_t timeout_ms)
{
  k_timeout_t to = (timeout_ms == OS_WAIT_FOREVER_MS) ? K_FOREVER : K_MSEC(timeout_ms);
  return (k_msgq_put(q, p_msg, to) == 0) ? 1 : 0;
}

static inline int OS_queue_recv_ms(OS_queue_t q, void *p_msg, uint32_t timeout_ms)
{
  k_timeout_t to = (timeout_ms == OS_WAIT_FOREVER_MS) ? K_FOREVER : K_MSEC(timeout_ms);
  return (k_msgq_get(q, p_msg, to) == 0) ? 1 : 0;
}

static inline void OS_queue_delete(OS_queue_t q) { (void)q; }

#else

/* ============================= FREERTOS ================================= */
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "queue.h"

#include "trcRecorder.h"
#include "dfm.h"
#include "dfmCrashCatcher.h"

#if (configSUPPORT_STATIC_ALLOCATION != 1)
  #error "FreeRTOS: configSUPPORT_STATIC_ALLOCATION must be 1 to use this OSAL."
#endif

typedef TaskHandle_t      OS_thread_t;
typedef TickType_t        OS_tick_t;
typedef SemaphoreHandle_t OS_mutex_t;
typedef QueueHandle_t     OS_queue_t;

#define OS_PRIO_HIGHEST 5
#define OS_PRIO_HIGH 4
#define OS_PRIO_MID 3
#define OS_PRIO_LOW 2
#define OS_PRIO_LOWEST 1



/* FreeRTOS requires explicit scheduler start. */
#define OS_start_scheduler()  do { vTaskStartScheduler(); } while (0); while(1){ /* Should never get here... */};

#define OS_delay_ms(ms_)  do { vTaskDelay(pdMS_TO_TICKS((ms_))); } while (0)
#define OS_get_tick_count() (xTaskGetTickCount())

static inline void OS_delay_until_ms(OS_tick_t *p_last_wake, uint32_t period_ms)
{
  vTaskDelayUntil(p_last_wake, pdMS_TO_TICKS(period_ms));
}

/* Convert bytes to StackType_t words (rounded up). */
#define OSAL_BYTES_TO_STACKWORDS_(bytes_)                                       \
  ( (uint32_t)(((uint32_t)(bytes_) + (uint32_t)sizeof(StackType_t) - 1u) / (uint32_t)sizeof(StackType_t)) )

/* --- Threads ------------------------------------------------------------- */
#define OS_THREAD_STORAGE(name_, stack_bytes_)                                  \
  static StaticTask_t name_##_tcb;                                              \
  static StackType_t  name_##_stack[OSAL_BYTES_TO_STACKWORDS_(stack_bytes_)];   \
  static OS_thread_t  name_##_handle = (OS_thread_t)0

#define OS_thread_create(name_, entry_fn_, arg_, prio_)                         \
  do {                                                                          \
    name_##_handle = xTaskCreateStatic(                                         \
        (TaskFunction_t)(entry_fn_),                                            \
        #name_,                                                                 \
        (uint32_t)(sizeof(name_##_stack) / sizeof(name_##_stack[0])),           \
        (void *)(arg_),                                                         \
        (UBaseType_t)(prio_),                                                   \
        name_##_stack,                                                          \
        &name_##_tcb);                                                          \
  } while (0)

#define OS_thread_delete(handle_)   do { vTaskDelete((handle_)); } while (0)
#define OS_thread_delete_self()     do { vTaskDelete(NULL); } while (0)

/* --- Mutex --------------------------------------------------------------- */
#define OS_MUTEX_STORAGE(name_)                                                 \
  static StaticSemaphore_t name_##_m;                                           \
  static OS_mutex_t name_##_handle = (OS_mutex_t)0

#define OS_mutex_create(name_)                                                  \
  do {                                                                          \
    name_##_handle = xSemaphoreCreateMutexStatic(&name_##_m);                   \
  } while (0)

static inline int OS_mutex_take_ms(OS_mutex_t m, uint32_t timeout_ms)
{
  TickType_t to = (timeout_ms == OS_WAIT_FOREVER_MS) ? portMAX_DELAY : pdMS_TO_TICKS(timeout_ms);
  return (xSemaphoreTake(m, to) == pdTRUE) ? 1 : 0;
}

static inline void OS_mutex_give(OS_mutex_t m)
{
  (void)xSemaphoreGive(m);
}

static inline void OS_mutex_delete(OS_mutex_t m)
{
  /* Static mutex: delete is a no-op in most demo scenarios. */
  (void)m;
}

/* --- Message queue ------------------------------------------------------- */
#define OS_QUEUE_STORAGE(name_, msg_size_, msg_count_)                           \
  static StaticQueue_t name_##_q;                                                \
  static uint8_t name_##_q_buf[(msg_size_) * (msg_count_)];                      \
  static OS_queue_t name_##_handle = (OS_queue_t)0;                              \
  enum { name_##_msg_size = (msg_size_), name_##_msg_count = (msg_count_) }

#define OS_queue_create(name_)                                                   \
  do {                                                                            \
    name_##_handle = xQueueCreateStatic(                                          \
        (UBaseType_t)(name_##_msg_count),                                         \
        (UBaseType_t)(name_##_msg_size),                                          \
        name_##_q_buf,                                                           \
        &name_##_q);                                                             \
  } while (0)

static inline int OS_queue_send_ms(OS_queue_t q, const void *p_msg, uint32_t timeout_ms)
{
  TickType_t to = (timeout_ms == OS_WAIT_FOREVER_MS) ? portMAX_DELAY : pdMS_TO_TICKS(timeout_ms);
  return (xQueueSend(q, p_msg, to) == pdTRUE) ? 1 : 0;
}

static inline int OS_queue_recv_ms(OS_queue_t q, void *p_msg, uint32_t timeout_ms)
{
  TickType_t to = (timeout_ms == OS_WAIT_FOREVER_MS) ? portMAX_DELAY : pdMS_TO_TICKS(timeout_ms);
  return (xQueueReceive(q, p_msg, to) == pdTRUE) ? 1 : 0;
}

static inline void OS_queue_delete(OS_queue_t q)
{
  /* Static queue: delete is a no-op in most demo scenarios. */
  (void)q;
}

#endif /* __ZEPHYR__ */

#ifdef __cplusplus
}
#endif
