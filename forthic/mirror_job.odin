package forthic

import "core:sync"

// A request from one Interpreter to run a word on another Interpreter,
// carrying the requesting interpreter's whole stack across and back so no
// per-word arity bookkeeping is needed.
Mirror_Job :: struct {
  word_name: string,
  stack:     Stack,
  err:       Error,
  mutex:     sync.Mutex,
  cond:      sync.Cond,
  done:      bool,
}

Mirror_Job_Queue :: struct {
  mutex: sync.Mutex,
  jobs:  [dynamic]^Mirror_Job,
}

mirror_job_queue_push :: proc(queue: ^Mirror_Job_Queue, job: ^Mirror_Job) {
  sync.mutex_lock(&queue.mutex)
  append(&queue.jobs, job)
  sync.mutex_unlock(&queue.mutex)
}

mirror_job_wait :: proc(job: ^Mirror_Job) {
  sync.mutex_lock(&job.mutex)
  for !job.done {
    sync.cond_wait(&job.cond, &job.mutex)
  }
  sync.mutex_unlock(&job.mutex)
}

mirror_job_signal_done :: proc(job: ^Mirror_Job) {
  sync.mutex_lock(&job.mutex)
  job.done = true
  sync.cond_signal(&job.cond)
  sync.mutex_unlock(&job.mutex)
}

// Runs every pending job against interp, in order. Meant to be called
// once per iteration of whichever loop owns interp (e.g. once per frame).
mirror_job_queue_drain :: proc(queue: ^Mirror_Job_Queue, interp: ^Interpreter) {
  sync.mutex_lock(&queue.mutex)
  jobs := queue.jobs
  queue.jobs = make([dynamic]^Mirror_Job, 0)
  sync.mutex_unlock(&queue.mutex)
  defer delete(jobs)

  for job in jobs {
    saved_stack := interp.stack
    interp.stack = job.stack

    word, found := interpreter_find_word(interp, job.word_name)
    if found {
      job.err = compiled_word_execute(interp, word)
    } else {
      job.err = Unknown_Word{word = job.word_name}
    }

    job.stack = interp.stack
    interp.stack = saved_stack

    mirror_job_signal_done(job)
  }
}
