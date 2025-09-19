open GlobalUniqueId
open Product
open Team
open InitiativePriority

@genType.import("./ProgressStatus") type progressStatus = ProgressStatus
@genType.import("./LifecycleStatus") type lifecycleStatus = LifecycleStatus

@genType
 type initiativeId = GlobalUniqueId.t

@genType
 type initiative = {
  id: initiativeId,
  productId: productId,
  title: string,
  description: option<string>,
  timeBudget: float,
  chatRoomLink: option<string>,
  progressStatus: progressStatus,
  lifecycleStatus: lifecycleStatus,
  isValidated: bool,
  validationEvidence: option<string>,
  outcomeNotes: option<string>,
  assignedTeamId: option<teamId>,
  priority: InitiativePriority.t,
}

@genType
let makeId = (~id=?, ()) => GlobalUniqueId.make(~id?, ())

@genType
let make = (
  ~productId,
  ~title,
  ~timeBudget,
  ~priority: InitiativePriority.t,
  ~description=?,
  ~chatRoomLink=?,
  ~progressStatus: option<progressStatus>=?,
  ~lifecycleStatus: option<lifecycleStatus>=?,
  ~isValidated=false,
  ~validationEvidence=?,
  ~outcomeNotes=?,
  ~assignedTeamId=?,
  ~id=?,
  (),
) => {
  id: makeId(~id?, ()),
  productId,
  title,
  description,
  timeBudget,
  chatRoomLink,
  progressStatus: Belt.Option.getWithDefault(progressStatus, ProgressStatus.Thinking),
  lifecycleStatus: Belt.Option.getWithDefault(lifecycleStatus, LifecycleStatus.Waiting),
  isValidated,
  validationEvidence,
  outcomeNotes,
  assignedTeamId,
  priority,
}

@genType
let sortByPriority = initiatives =>
  initiatives
  ->Belt.Array.copy
  ->Belt.Array.sort((a, b) => InitiativePriority.compare(a.priority, b.priority))

@genType
let assignToTeam = (~initiative, ~teamId) => {
  ...initiative,
  assignedTeamId: Some(teamId),
}

@genType
let unassignTeam = initiative => {
  ...initiative,
  assignedTeamId: None,
}

@genType
let updateProgressStatus = (~initiative, ~status) => {
  ...initiative,
  progressStatus: status,
}

@genType
let updateLifecycleStatus = (~initiative, ~status) => {
  ...initiative,
  lifecycleStatus: status,
}

@genType
let validate = (~initiative, ~evidence=?) => {
  ...initiative,
  isValidated: true,
  validationEvidence: evidence,
}

@genType
let invalidate = initiative => {
  ...initiative,
  isValidated: false,
  validationEvidence: None,
}

@genType
let addOutcomeNotes = (~initiative, ~notes) => {...initiative, outcomeNotes: Some(notes)}

@genType
let clearOutcomeNotes = initiative => {...initiative, outcomeNotes: None}

@genType
let updatePriority = (~initiative, ~priority) => {...initiative, priority}

@genType
let rename = (~initiative, ~title) => {...initiative, title}

@genType
let updateDescription = (~initiative, ~description) => {...initiative, description: Some(description)}

@genType
let clearDescription = initiative => {...initiative, description: None}

@genType
let updateTimeBudget = (~initiative, ~timeBudget) => {...initiative, timeBudget}

@genType
let updateChatRoomLink = (~initiative, ~chatRoomLink) => {...initiative, chatRoomLink: Some(chatRoomLink)}

@genType
let clearChatRoomLink = initiative => {...initiative, chatRoomLink: None}
