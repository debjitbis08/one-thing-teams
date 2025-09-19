@genType
type taskId = string

@genType
type task = {
  id: taskId,
  title: string,
  isComplete: bool,
}

let sanitizeTitle = (title: string) => title->Js.String2.trim

@genType
let make = (~id, ~title, ~isComplete=false, ()) => {
  let cleanTitle = sanitizeTitle(title)
  if cleanTitle == "" {
    Belt.Result.Error("Task title cannot be empty")
  } else {
    Belt.Result.Ok({id, title: cleanTitle, isComplete})
  }
}

@genType
let markComplete = task => {...task, isComplete: true}
