---
name: impire-agents
description: Add and operate an agent in an Impire workspace — write its document (instructions, model, toolkits, stores, memory, knowledge, conversations, triggers), choose whom it acts as, read its runs, fire a trigger by hand, stop, start and delete it, and read what a status word means. Use when asked to create or change an Impire agent, to make something happen in a workspace when a store changes, a request arrives, a message is published or a time comes, to have an agent talk in conversations, or to find out why an agent is idle, paused, not configured or waiting for approval.
license: Sustainable Use License 1.0 (see LICENSE at the repo root)
metadata:
  author: impire
  version: "0.1.0"
---

# impire-agents — adding and operating an agent

An Impire **agent** is a process with its own identity that acts on events by calling inference and toolkits, keeps its own state, and answers to the workspace that owns it. Nobody writes code to have one: an agent is one **workload** of the workspace, running the platform's **agent image**, made into *this* agent by a **document** an admin writes in words, fired by its **triggers**, and recorded run by run under a **namespace of its own** in the workspace's `agents` store. This skill teaches the semantics — what the document says, what fires an agent, what a run is, whom its calls are made as, and what each status word means — which are stable. Command flags and tool names drift: `impire agents <verb> -h` is authoritative for the flags, a run's page shows the tools as the model saw them, and you should prefer both over anything you remember.

An agent is **event-driven and not a loop**. An event makes it act, and the event is where the platform's contract ends; what handles the event — the harness — works inside however it works. Nothing runs an agent that nothing has fired, and an agent does not poll or wake itself: it **sleeps** when it has had nothing to do for a while, and the platform wakes it on what it declared it listens for.

## First: where you stand

- You need to be an **admin** of the workspace to add, change, stop, start, fire or delete an agent. A **member** sees the agents that are up, what each is for, whom it acts as, and may *Send a request* to one that has a request trigger — and reads nothing of an agent's runs.
- Two clients of one list: the console's **Agents** page (under *Administration*, beside Toolkits, at `agents`; an agent at `agents/<agent>`, a run at `agents/<agent>/<run>`) and the terminal client's command group **`impire agents`**. Sign the terminal client in first (`impire login <workspace>`); `--output json` gives the wire's form on every command.
- The agent uses what the workspace already has: a **model** it thinks with (an inference instance the workspace runs), the **toolkits** it may call, the **stores** it may read or write, and the **knowledge bases** it may ask. Add those first; the document names them by their workspace names, and a document naming something that does not exist is refused.
- Run `impire version`. The `agents` group exists from **v0.13.0** of the client, and later verbs (memory among them) arrived after it; `impire agents -h` lists what your client has. Upgrade rather than adapt.

## The document

The document is the agent. It is the workload's settings document in the configuration service — written by an admin, replaced whole, watched by the running agent — and the console's *Add an agent* form and `impire agents add <file>` are two ways of writing the same thing. Its fields:

| Field | What it says |
|---|---|
| `name` | the agent's name — a subject token, `[a-z0-9-]+`, unique in the workspace, the name callers find it under and the name in the address; it cannot be renamed later |
| `display-name`, `description` | what people read; both are also what discovery says of the agent, so every list of agents names it as people read it |
| `acts` | whom the agent acts as: `for-caller` or `as-itself` (below) |
| `instructions` | who the agent is and what it is for, in words — handed to the model with every event |
| `model` | the workspace's name for the model it thinks with |
| `params` | the sampling parameters it asks the model with, in the inference contract's names |
| `toolkits` | the toolkits it may call — the workspace's registered toolkits, and any of the platform's own `workflows`, `agents` and `platform` toolkits (below) |
| `stores` | a list of `{name, write}` — the stores it may read, and which it may write. Its own namespace in `agents` is never listed and is always both |
| `memory` | optional — whether and how the agent remembers across runs: how it recalls (by tool, or before each run), how it remembers (by tool, or by reflecting after each run), a recall limit, and how long observations are kept. Absent, every run starts fresh |
| `knowledge` | optional — the knowledge bases the agent may ask; each must exist and admit the agent in its audience |
| `audience` | who may bring the agent into a conversation: everyone, or named groups and agents; admins always may |
| `home` | optional — the conversation where what the agent says of its own accord goes: a schedule's outcome, a decided approval's result, a failed run's line |
| `voice` | optional — the voice a conversation speaks the agent's turns in; the agent itself thinks and writes in text |
| `triggers` | a list; each has a `name`, a `kind`, the kind's parameters, and its own `instructions` — what to do when it fires |

One document, in its own form:

```yaml
name: orders-clerk
display-name: Orders clerk
description: Confirms each new order and flags the ones that need a person.
acts: as-itself
instructions: |
  You keep the orders store tidy. …
model: fast
params: { temperature: 0.2 }
toolkits: [mail, directory]
stores:
  - { name: orders, write: true }
  - { name: customers, write: false }
triggers:
  - name: new-order
    kind: state
    store: orders
    operations: [created]
    instructions: |
      Read the order, look the customer up, mail a confirmation, and set its status. …
  - name: ask
    kind: request
    instructions: Answer what you are asked about the orders you handle.
  - name: morning-review
    kind: schedule
    cron: "0 0 9 * * 1-5"
    zone: Europe/Brussels
    instructions: List yesterday's orders still open and mail the summary to sales.
```

**What is checked.** The configuration service checks the grammar; the agent itself checks the meaning, and until the document arrives and validates the agent shows **not configured** with the reason. The name must equal the registration's; `acts` is one of its two values; every toolkit, store and knowledge base named must exist in the workspace, and each base must admit the agent; a document with `memory` needs the workspace's memory store, which the console makes the first time any agent is given memory; every trigger needs a name unique in the document and a kind the agent knows; a `request` trigger's name may not be a token the platform reserves after a workload's id (`infer`, `tool`, `callout`, `transform`, `fire`, `settings`); a `schedule` names exactly one time; a `subject` is under `event.`, and no two of an agent's subjects may overlap — two subjects one message could match are refused, naming the trigger. **A refused document says why**: the agent publishes the reason where every client reads it, so the console and `agents get` show it under the status. A document refused while another runs changes nothing — the running document stays.

**Changing it.** Save the document again — the *Settings* tab, or `impire agents set <agent> <file>`. The change is applied without a restart and takes effect at the agent's **next event**: a run in flight finishes under the document it started with; triggers added are held from then on, triggers removed fire no more.

**Memory and knowledge.** With a `memory` field the agent has a memory: it remembers by tool, or by a reflection the harness makes after each run, and recalls by tool, or before each run; what it remembers is kept under its own namespace in the workspace's memory store, shown on the agent's *Memory* tab, and forgotten there one observation at a time. With a `knowledge` field it may ask the named bases what the workspace holds to be true; it reads facts and never writes one — a fact arrives through a knowledge pipeline and a person's yes. Without either, what an agent knows from before is what the workspace's stores hold.

**In conversations.** An agent talks in the workspace's conversations by one choice in the form, *Talks in conversations*; under it, who may bring it in (`audience`), what it does there, and where it speaks on its own (`home`). The console writes the request trigger the conversations service hands a conversation to; you never write or read that trigger by hand, and a request trigger added by hand under its name is refused. With the choice off, none of the section is written.

**An agent a solution brings** is registered by the solution's installer, not by an admin. Its document is the solution's — composed from the manifest and the solution's settings, rewritten at every install and upgrade — shown as *brought by <solution>* and read-only on the Agents page. In every other respect it is an agent as this skill describes.

## Whom the agent acts as

`acts` is set per agent and decides whose name every call of a run is made under.

- **`for-caller`** — *acts for whoever asks it*. A run fired by a **request** acts for the sender: the sender is the principal, the agent the actor, so a person-scoped toolkit spends that person's own link, the rules read the person, and the usage is the person's. Such an agent does for people what they may do themselves, and nothing more. A run fired by anything that carries no caller — an operation, a message, a schedule — is the agent's own.
- **`as-itself`** — *acts as itself*, the colleague. Every run is the agent's own whatever fired it; a request's sender is recorded on the run and not acted for. The rules read the agent: an admin who wants to bound such an agent writes rules **about the agent**, and a rule written about a person does not see what the person asked it to do — that is the point of such an agent, not a hole in it. Acting as itself an agent reaches `tenant`- and `none`-scoped toolkits; a `person`-scoped toolkit answers it as it answers anyone who holds no link, since an agent cannot hold a link of its own yet.

**In a conversation** the run is the agent's own whatever `acts` says, since a conversation has many speakers and no caller — except a **private** conversation, which has one person: there a `for-caller` agent acts as that person. Memory and knowledge are always read with the agent's own identity, so a `for-caller` agent reads what the agent may read and never what its caller may.

The model is told who sent the event — the sender's kind (member, admin, app, workload) and, for a person, their groups — as a fact of the platform's, so an agent weighs who asks on that and never on what the message claims.

A request's carrier lives for minutes. A run for a caller that outlives it has its remaining calls refused, and the sender sends again.

## Triggers: the four kinds

A trigger says which events the agent acts on and, in its own instructions, what to do then. Everything that fires an agent reaches it on its own family of subjects or on a watch the agent itself holds; there is no second door.

| Kind | Names | Fires when | Whom the run acts for |
|---|---|---|---|
| **state** | a `store`; the `operations` that fire it (all when absent); a `path` under the store (the whole store when absent) | an operation matching them is applied to an instance under the path — by anyone **but the agent itself** | the agent itself |
| **request** | nothing but its `name`, which is the verb | a request arrives on the agent's family under that verb, from a member, a workload or an admin | the sender where `acts: for-caller`; the agent where `as-itself` |
| **subject** | a `subject` of the workspace's events, under `event.`; `*` for one token, `>` for the rest | a message is published there by anyone in the workspace | the agent itself; the publisher is recorded |
| **schedule** | exactly one of `cron` (six fields: seconds, minutes, hours, day of month, month, day of week), `every` (a duration) or `at` (one time); `zone`, an IANA name for `cron`, UTC when absent | the time comes, by the bus's own scheduling | the agent itself |

**State.** *When an order is placed* and *when this one order changes* are the same kind, with and without a path. The event the agent is handed carries the instance's path, its state now, and the operations since the agent last looked, with who made them. Two things are decided without asking a model: the agent's **own writes never fire it**, so an agent that writes to what it watches does not call itself; and operations on one instance that arrive **while a run is busy coalesce** into one event with the latest state, delivered when the run ends. Operations on several instances are several events, in order.

**Request.** The verb is `<name>` on the agent's own family; whoever the broker admits there may send one. The body is the message; the reply is the run's answer, streamed as frames and ended with a terminator; a run that ends `failed` ends the reply with the refusal. A request that arrives while a run is open waits its turn; one that would wait past the run bound is refused `busy`, and the caller may send again. A rule may guard the verb as it guards any verb. *Send a request* on the console and `impire agents send <agent> <trigger> <text>` are one request and one reply — not a conversation; nothing is kept in the browser.

**Subject.** The workspace's events are the family `event.>` inside the workspace: members, workloads and admins **publish** on it, nobody subscribes it directly, and the platform keeps what is published for the install's retention (seven days by reference), recording who published it, and delivers each kept message to every agent that declared a matching subject. A subject under `event.` is the publisher's to choose and the trigger's to name — `mail.received`, `orders.placed`. **An event says what happened and names the thing; it does not carry the thing**: the agent reads the mail, the order, the file through its tools, under the workspace's rules. Any number of agents may listen on one subject and each receives every message; the publisher learns nothing of who listened. A message that names the agent itself as its writer does not fire it, as its own store writes do not. A message that finds a run open waits its turn in arrival order, beside the requests. A message published while the agent was **stopped** is not delivered — the agent resumes with the events from then on, not with the backlog; one published while the agent was asleep or merely being replaced (a roll, a boot) waits and is delivered. There is no replay of a subject's history to a new trigger. **An outside system reaches a subject trigger through a source**: the gateway's source face publishes a webhook's POST onto the workspace's events under the source's own subjects, and a subject trigger names them as any subject — what such a message proves is the agent's to check, since the face verifies nothing of the provider's.

**Schedule.** *Every weekday at four* is `cron: "0 0 16 * * 1-5"` with `zone: Europe/Brussels`. The agent treats the server's publish as a prompt and **its own clock as the judge**: it reckons from the expression, the zone and when it last ran whether a time has come, runs **once** if one has, and writes that time down. Two due times that fell inside one run come to one run. After an absence — a boot, a wake, a start after a stop — a schedule catches up **once, never once per time missed**: an agent that was down for a week runs its daily trigger once. A `cron` in a zone with daylight-saving time may see a time skipped or doubled at the change; UTC does not. Nothing finer than a second.

**Trying a trigger by hand.** An admin may fire any trigger from the agent's *Triggers* tab or with `impire agents fire <agent> <trigger> [<file>]`: for a state, subject or schedule trigger the admin writes the event in the kind's shape — an instance's path, a message's body, nothing for a schedule; a request trigger is simply sent a request, with the admin as its caller. A run fired by hand is the agent's own, acts as a run of that kind acts, is marked *fired by hand, by whom* in its record, and **does not move the agent's cursors**. Only an admin can fire: the broker refuses everyone else.

## Sleep

An agent **sleeps after a minute with nothing to do**, unless its registration says otherwise — the *sleeps after* field on the agent's *Settings*, shown filled with one minute; cleared, it never sleeps. A sleeping agent holds no microVM and is woken by whatever it declared it listens for: a request, a kept message, a schedule's time, an operation on a watched store. **An open run, and the events waiting their turn, keep it awake**, so no run is cut short by a sleep. The first event after a sleep waits for the agent to boot — a few seconds — and a woken agent catches up a missed schedule once, as after any boot. Nothing in the document changes for sleep.

## A run

A **run** is one event's work: opened when the agent hands the event to the harness, ended when the harness says how it went — `done`, `failed`, or `stopped` when an admin stopped the agent while it ran. Each run is on the agent's page with the trigger that fired it.

- **One run at a time, in order.** Events wait their turn. A harness may do several things at once inside a run; an agent that should hold several runs open is the day someone measures the need. One agent, one replica.
- **An event opens one run, however often it is delivered.** The run's id is derived from the trigger and the event, so the same event handed over a second time finds the run it opened.
- **A lost placement hands the event over again**, saying which time this is. After the **third** handing-over the run is closed `failed` and the agent takes the next event.
- **A run that fails says so where it was fired.** A run that ends `failed` or `stopped` is said in one line, as the agent, in the conversation its event names — or in the agent's `home` — with the harness's words.
- **Bounds an admin does not have to think about** — install settings, the operator's to change; the reference values: a run's time **15 minutes** (at it the run ends `failed`, a call in flight cancelled); runs opened in an hour **120** (at it the agent takes no event and shows **paused: too many runs** until an admin stops and starts it — the pause survives a crash and is what stops two agents that fire each other, or an agent whose tool changes what it watches, before anyone notices the bill); model requests in a run **50** (at it the run ends `done` with the model's last words, saying so); handings-over of one event **3**; and the **model's window** — the harness keeps a run inside it (below), and a run that cannot be kept inside it ends saying so.
- **A failed run leaves the agent enabled.** Nothing but an admin disables an agent, and an agent disables nothing.

### What the platform's harness does with an event

The harness asks the document's model with the agent's instructions, the trigger's instructions, what happened and who sent it, and one definition per tool; runs each call the model asks for, one at a time, in the model's order; gives each result back as the tool's turn; and asks again until the model asks for nothing. That text is the answer, and the run ends `done`. Its rules:

- **A turn identical to the previous one is not run**, checked **before** its calls are executed — a model that has finished sometimes repeats its closing turn with the calls it already made attached, and a repeated call may be a write. The run ends `done` with the model's words.
- **A failed call is given back in the tool's own words** — a refusal, a toolkit's error, a store's refusal — and the run goes on; the model decides what to do with it.
- **Every turn is written as it happens** to the agent's record, so the agent's page shows it, and a second handing-over continues from what was written.
- **A run that acted ends with a line.** When the model stops with no words after making calls, the harness asks it once more for one line: what was done, each artifact by its link, the person's next act.
- **Every run starts from what the agent remembers, and nothing else.** The harness carries nothing from one run to the next itself; with a `memory` field the agent recalls and remembers as the field says.
- **The run's context is accounted for.** The harness counts what the model reads by the provider's own count; a single result larger than a quarter of the window reaches the model cut, with a line saying so and how to ask for a narrower slice; as the window fills it first leaves out the oldest results, then has the model write itself a note and starts over from it — at most three notes, then the run ends `done` saying the window was reached. The whole result stays on the run's turn either way. The *Runs* tab shows each run's requests, tokens against the window, and compactions in one line.

The tools the model sees are exactly these — write your instructions with them in mind:

| Tools | What the model gets |
|---|---|
| each tool of each registered toolkit in `toolkits` | the tool under the toolkit's name, with the toolkit's own description and schema, unchanged |
| the state tools, for each store in `stores` | get, list and history on every store named, and apply where the store is marked `write`; the store's name is a parameter, and an operation's body is the store's type's. **The list is a page**: a limit, fifty by default, and a cursor the result carries for the next page — a whole type never lands in the model's context at once |
| the platform's `memory` toolkit, where the document has a `memory` field | remember, recall and forget — always as the agent itself |
| the platform's `knowledge` toolkit, where the document's `knowledge` names bases | query and walk the named bases — always as the agent itself |
| the platform's `workflows`, `agents` and `platform` toolkits, where `toolkits` names them | the workspace's verbs for those things, spoken on the agent's own connection with the run's identity; what succeeds is what the agent's template admits, and a refusal is the tool's turn |

Every toolkit tool, the platform's included, follows the toolkit contract's naming, toolkit then tool; the exact strings are on the toolkit's page and in a run's turns.

### A call a rule escalates

When a workspace rule escalates one of the agent's calls, the call is **refused** at the enforcement point with the escalation's id, as for anyone. For a run that is the agent's own, the crossing is addressed to the workspace's **admins** whatever the rule's approver says — there is nobody else to ask — and shows on Approvals naming the agent and the run; the agent's page shows **waiting for approval**. The run goes on without the result: the model is told *refused; an admin has been asked*, and the run ends as it ends. When an admin **grants** it, the agent issues the kept call again exactly, and the result arrives as a **new event of the same trigger** — *the call you were refused was approved and ran; this is its result* — which opens a new run. Denied or expired: an event saying so, the same way. The agent approves nothing and holds no grant.

In a run that acts **for its caller**, the crossing is the caller's, addressed as the rule says, and the reply ends with the refusal and the escalation id; the caller decides it where they are and sends again.

### The checks

At every run's close the platform checks what a single run can answer — it ended; every call's tool is one the document names; the run's turn bound held; every escalated call got an outcome; every call named the principal the document says — and, per trigger, that its cursor advanced and that a schedule fired when due. A failed check is marked on the *Runs* and *Triggers* tabs, counted on the Agents list, and published on the workspace's events so that another agent or a solution may act on it. The checks judge no words, read no call's body, and stop no agent.

## Adding, operating, deleting

**Add an agent** (the console's form, or `impire agents add <file>` with the document) composes, in this order: the workload's registration on the platform's agent image, with the agent's name, one replica and no egress; the workspace's **`agents` store, once** — the first agent anyone adds makes it, with the record's types, and every later add finds it there; then the document. Nothing in the store is created per agent. A failure midway is shown where it happened and **what was created stays** — an agent the table shows *not configured*. Save again, or `agents add` again with the same name, **completes what is missing**: the console reads before it writes and creates nothing twice. Nothing is rolled back. An agent **is not ready** until the store, its types and the document are all there.

**The registration** is the platform's: the agent image, pinned by the install and followed when the install moves it; one replica; **no egress** — the agent reaches the bus and nothing else, and an external system is a toolkit's to reach; the install's default resources or what the admin chose; and when it sleeps (§ sleep). An agent counts against the workspace's workload, vCPU and memory limits as one workload and is no plan feature of its own.

**The status word**, one per agent, the first that holds:

| Word | Means |
|---|---|
| **stopped** | the registration is suspended: nothing runs, nothing fires |
| **not configured** | the document is absent or refused, or something it names is missing; the agent is up and does nothing until it holds one it accepts — the reason is shown |
| **paused** | the hour's ceiling of runs was reached; the agent holds events until an admin stops and starts it |
| **waiting for approval** | a crossing the agent caused is open on Approvals |
| **working** | a run is open |
| **idle** | the agent runs, or sleeps, with no run open |

A member sees the agents that are up as *available*; a stopped or not-yet-configured agent is not on a member's page.

**Stop** and **Start** (`impire agents suspend <agent>`, `impire agents resume <agent>`) are the workload's emergency stop and its reversal. **Stop** destroys the placement: an open run is closed `stopped` and not taken up again, the agent's schedules end, its subject messages stop being delivered, and nothing is kept for it while it is stopped. **Start** boots it: it reads its document and its cursors, declares what it listens for, and **catches up once** — each instance that changed under a watched path while it was away, once, in its state now; each schedule from its next time, never for the times missed; nothing of the messages published on its subjects meanwhile. Stop and start is also how an admin lifts a pause.

**Delete** (`impire agents delete <agent>`, which asks unless told not to) retires the registration and deletes the document. **Nothing of its record is deleted**: its runs and memories stay under the retired agent's namespace, readable by admins and written by nobody, and the calls it made stay in the workspace's records. The registration stays, retired, so the records keep their attribution.

**The terminal client's group**, verb by verb — `impire agents <verb> -h` for the flags:

- `agents list` — a member's list; `--everyone` for an admin's table with the statuses and whether each talks in conversations.
- `agents add <file>` — the document from a file; prints the workload id; finishes a half-made agent when run again.
- `agents get <agent>` — the registration's status, whether it talks in conversations, the document, the triggers with when each last fired.
- `agents set <agent> <file>` — replace the document.
- `agents runs <agent>`, `agents run <agent> <run>` — the runs, newest first; one run with its turns; `--follow` on an open run.
- `agents send <agent> <trigger> <text>` — a request; the reply's frames to standard output as they arrive.
- `agents fire <agent> <trigger> [<file>]` — fire a state, subject or schedule trigger by hand.
- `agents suspend <agent>`, `agents resume <agent>` — stop, start.
- `agents delete <agent>` — asks, unless `--yes`.
- `agents memory <agent>`, `agents forget <agent> <observation>` — what the agent remembers, and forgetting one thing of it.

`<agent>` is the name; the client resolves it to the workload id.

## The record

Every agent keeps its record under a **namespace of its own** — its workload id — in **one store of the workspace, `agents`**. It is a **scoped** store: the agent reads and writes its own namespace and can address no other, and nothing it writes or reads names the namespace; the workspace's **admins** read every namespace, which is how the agent's page is drawn; a member and every workload that is not an agent reach nothing in it. It holds, per agent: each **run** — the trigger and its kind, the event or its digest, who sent it where someone did, whom the run acts for, when it opened and ended and how, how often it was handed over, whether an admin fired it by hand, each kept call while its crossing is open, its checks, and its context line; each run's **turns** — the model's text, each call with its arguments, each result, in order, and any note the harness wrote at a compaction; and each trigger's **cursor** — where a state trigger has read to, and when a schedule last fired and was last due. The store also carries a **view of the runs that are open or hold a kept call**, declared with the store and partitioned by agent as the store is, so the agent finds its open runs without listing every run it ever held.

What the agent remembers is not in this store but in the workspace's memory store, under its namespace there. The record the workspace **always** has, whatever the harness, is the calls: every model asked and every tool called is in the workspace's own records under the agent's name, as every workload's calls are. The `agents` store is never one of the stores an agent watches.

## Writing good instructions

- **The agent's `instructions` are its standing orders; a trigger's `instructions` are the handler.** Both are handed to the model with every event, so say in the trigger's text what to do with *this* kind of event, and in the agent's text who it is, which stores and toolkits it works with, and what it must never do.
- **Name the stores and tools as the model sees them**, and say when to read before writing: an agent that writes to a store it watches does not fire itself, so a status change is safe. A run's page shows each tool call by the name the model used.
- **Read one thing by its key; list a page, and list a type.** The model reads an instance it can name directly, and a list comes back a page at a time with a cursor for the next. Tell it which type to list rather than listing everything under a path its children share, to stop when it has what it needs, and never to read every item of a list one by one to answer a count — keep the answer in a record of its own and read that.
- **Say what to remember.** With a `memory` field, tell the agent what is worth remembering and what is not, or let it reflect after each run; without one, what it needs next time must be written to a store it may write.
- **Expect a bounded run.** Fifty model requests, fifteen minutes and the model's window by reference; an agent asked to do a large job should write progress to a store and let the next event continue.
- **Put the boundary in rules, not in prose.** An agent acting as itself is governed by rules written about the agent; a rule that escalates a tool asks an admin and the agent is told it was refused. Prose that says *never send mail without asking* is a wish; a rule is a guarantee.
- **Prefer narrow triggers.** `operations: [created]` and a `path` over the whole store; a subject over a wildcard; a weekday cron in the workspace's zone over `every`.

## What agents do not do, in this increment

Do not promise these: a **brought harness** (your own harness image handed the events — the boundary is drawn, a later increment fills it); a **fact written by an agent** (an agent reads knowledge and remembers; facts arrive through pipelines); a **mailbox** as a source (a webhook is a source; a mailbox is its own feature); a **link of the agent's own** at an upstream (person-scoped toolkits answer an agent acting as itself as they answer anyone without a link); an **agent as a model** on the gateway's faces or in the chat's picker; **orchestration across agents** (an agent may send another a request; nothing above them plans or hands off); **several replicas**, and so several runs at once; a **conversation through *Send a request*** (it is one request and its reply — an agent talks in conversations through *Talks in conversations*); **renaming** an agent; a **marketplace of agents** (an agent a workspace installs ready-made comes in a solution).

## For developers

The SDKs carry the agent's contract so that a client or a tool can speak it without restating it: the document's shape and its validation, the reserved trigger names, the record's types and its view of open runs as a surface declares them, how a run's id and a schedule's due time are derived, and the fire-by-hand subject — the `agent` package of `impire-sdk-go` and the `agent` module of `impire-sdk-js`. Read those for signatures; this skill states only the semantics they implement.

## Sources

Derived from the Impire hq's design, which is authoritative where this skill and the platform disagree: `02-DESIGN/22-agents/01-the-agent.md` (the agent, the document, whom it acts as, the agents' store, enabled and disabled, sleep), `02-triggers.md` (the four kinds, catching up, firing by hand), `03-a-run.md` (a run, the harness, the bounds, the context, escalations, the record, the open-runs view, the paged list), `04-the-agents-surface.md` (the page, the form, the statuses, the verbs), and decisions `0091`, `0183`, `0197`, `0198` and `0200`. See `DERIVATION.md` at the repo root.
