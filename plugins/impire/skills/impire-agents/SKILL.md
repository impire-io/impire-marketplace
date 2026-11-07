---
name: impire-agents
description: Add and operate an agent in an Impire workspace — write its document (instructions, model, toolkits, stores, triggers), choose whom it acts as, read its runs, fire a trigger by hand, stop, start and delete it, and read what a status word means. Use when asked to create or change an Impire agent, to make something happen in a workspace when a store changes, a request arrives, a message is published or a time comes, or to find out why an agent is idle, paused, not configured or waiting for approval.
license: Sustainable Use License 1.0 (see LICENSE at the repo root)
metadata:
  author: impire
  version: "0.2.0"
---

# impire-agents — adding and operating an agent

An Impire **agent** is a process with its own identity that acts on events by calling inference and toolkits, keeps its own state, and answers to the workspace that owns it. Nobody writes code to have one: an agent is one **workload** of the workspace, running the platform's **agent image**, made into *this* agent by a **document** an admin writes in words, fired by its **triggers**, and recorded run by run under a **namespace of its own** in the workspace's one `agents` store. This skill teaches the semantics — what the document says, what fires an agent, what a run is, whom its calls are made as, and what each status word means — which are stable. Command flags drift: `impire agents <verb> -h` is authoritative, and you should prefer it over anything you remember about the flags.

An agent is **event-driven and not a loop**. An event makes it act, and the event is where the platform's contract ends; what handles the event — the harness — works inside however it works. Nothing runs an agent that nothing has fired, and an agent does not poll, wait or wake itself.

## First: where you stand

- You need to be an **admin** of the workspace to add, change, stop, start, fire or delete an agent. A **member** sees the agents that are up, what each is for, whom it acts as, and may *Send a request* to one that has a request trigger — and reads nothing of an agent's runs.
- Two clients of one list: the console's **Agents** page (on the rail beside Toolkits, at `agents`; an agent at `agents/<agent>`, a run at `agents/<agent>/<run>`) and the terminal client's command group **`impire agents`**. Sign the terminal client in first (`impire login <workspace>`); `--output json` gives the wire's form on every command.
- The agent uses what the workspace already has: a **model** it thinks with (an inference instance the workspace runs), the **toolkits** it may call, and the **stores** it may read or write. Add those first; the document names them by their workspace names, and a document naming something that does not exist is refused.
- Run `impire version`. The `agents` group exists from **v0.13.0** of the client; upgrade rather than adapt.

## The document

The document is the agent. It is the workload's settings document in the configuration service — written by an admin, replaced whole, watched by the running agent — and the console's *Add an agent* form and `impire agents add <file>` are two ways of writing the same thing. Its fields:

| Field | What it says |
|---|---|
| `name` | the agent's name — a subject token, `[a-z0-9-]+`, unique in the workspace, the name callers find it under and the name in the address; it cannot be renamed later |
| `display-name`, `description` | what people read; the description is also what discovery says of the agent |
| `acts` | whom the agent acts as: `for-caller` or `as-itself` (below) |
| `instructions` | who the agent is and what it is for, in words — handed to the model with every event |
| `model` | the workspace's name for the model it thinks with |
| `params` | the sampling parameters it asks the model with, in the inference contract's names |
| `toolkits` | the toolkits it may call; each tool is offered to the model as `<toolkit>__<tool>`, declared exactly as the toolkit declares it |
| `stores` | a list of `{name, write}` — the workspace's stores it may read, and which it may write. Its own namespace in the `agents` store is never listed and is always both |
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

**What is checked.** The configuration service checks the grammar; the agent itself checks the meaning, and until the document arrives and validates the agent shows **not configured** with the reason. The name must equal the registration's; `acts` is one of its two values; every toolkit and store named must exist in the workspace; every trigger needs a name unique in the document and a kind the agent knows; a `request` trigger's name may not be a token the platform reserves after a workload's id (`infer`, `tool`, `callout`, `transform`, `fire`, `settings`); a `schedule` names exactly one time; a `subject` is under `event.`.

**Changing it.** Save the document again — the *Settings* tab, or `impire agents set <agent> <file>`. The change is applied without a restart and takes effect at the agent's **next event**: a run in flight finishes under the document it started with; triggers added are held from then on, triggers removed fire no more.

**No memory, no knowledge — yet.** Every run starts fresh. What an agent knows from before is what it wrote down: a note in its namespace of the `agents` store, or the workspace's own things in the stores it may read. Memory and knowledge are features to come, and will be hooked in by a field added to this document.

## Whom the agent acts as

`acts` is set per agent and decides whose name every call of a run is made under.

- **`for-caller`** — *acts for whoever asks it*. A run fired by a **request** acts for the sender: the sender is the principal, the agent the actor, so a person-scoped toolkit spends that person's own link, the rules read the person, and the usage is the person's. Such an agent does for people what they may do themselves, and nothing more. A run fired by anything that carries no caller — an operation, a message, a schedule — is the agent's own.
- **`as-itself`** — *acts as itself*, the colleague. Every run is the agent's own whatever fired it; a request's sender is recorded on the run and not acted for. The rules read the agent: an admin who wants to bound such an agent writes rules **about the agent**, and a rule written about a person does not see what the person asked it to do — that is the point of such an agent, not a hole in it. Acting as itself an agent reaches `tenant`- and `none`-scoped toolkits; a `person`-scoped toolkit answers it as it answers anyone who holds no link, since an agent cannot hold a link of its own yet.

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

**Subject.** The workspace's events are the family `event.>` inside the workspace: members, workloads and admins **publish** on it, nobody subscribes it directly, and the platform keeps what is published for the install's retention (seven days by reference) and delivers each kept message to every agent that declared a matching subject. A subject under `event.` is the publisher's to choose and the trigger's to name — `mail.received`, `orders.placed`. **An event says what happened and names the thing; it does not carry the thing**: the agent reads the mail, the order, the file through its tools, under the workspace's rules. Any number of agents may listen on one subject and each receives every message; the publisher learns nothing of who listened. A message published while the agent was **stopped** is not delivered — the agent resumes with the events from then on, not with the backlog; one published while the agent was merely being replaced (a roll, a boot) waits and is delivered. There is no replay of a subject's history to a new trigger. No webhook or mailbox publishes onto `event.>` yet: in this increment the publishers are members, workloads and admins.

**Schedule.** *Every weekday at four* is `cron: "0 0 16 * * 1-5"` with `zone: Europe/Brussels`. The agent treats the server's publish as a prompt and **its own clock as the judge**: it reckons from the expression, the zone and when it last ran whether a time has come, runs **once** if one has, and writes that time down. Two due times that fell inside one run come to one run. After an absence — a boot, a start after a stop — a schedule catches up **once, never once per time missed**: an agent that was down for a week runs its daily trigger once. A `cron` in a zone with daylight-saving time may see a time skipped or doubled at the change; UTC does not. Nothing finer than a second.

**Trying a trigger by hand.** An admin may fire any trigger from the agent's *Triggers* tab or with `impire agents fire <agent> <trigger> [<file>]`: for a state, subject or schedule trigger the admin writes the event in the kind's shape — an instance's path, a message's body, nothing for a schedule; a request trigger is simply sent a request, with the admin as its caller. A run fired by hand is the agent's own, acts as a run of that kind acts, is marked *fired by hand, by whom* in its record, and **does not move the agent's cursors**. Only an admin can fire: the broker refuses everyone else.

## A run

A **run** is one event's work: opened when the agent hands the event to the harness, ended when the harness says how it went — `done`, `failed`, or `stopped` when an admin stopped the agent while it ran. Each run is on the agent's page with the trigger that fired it.

- **One run at a time, in order.** Events wait their turn. A harness may do several things at once inside a run; an agent that should hold several runs open is the day someone measures the need. One agent, one replica.
- **An event opens one run, however often it is delivered.** The run's id is derived from the trigger and the event, so the same event handed over a second time finds the run it opened.
- **A lost placement hands the event over again**, saying which time this is. After the **third** handing-over the run is closed `failed` and the agent takes the next event.
- **Bounds an admin does not have to think about** — install settings, the operator's to change; the reference values: a run's time **15 minutes** (at it the run ends `failed`, a call in flight cancelled); runs opened in an hour **120** (at it the agent takes no event and shows **paused: too many runs** until an admin stops and starts it — the pause survives a crash and is what stops two agents that fire each other, or an agent whose tool changes what it watches, before anyone notices the bill); model requests in a run **50** (at it the run ends `done` with the model's last words, saying so); handings-over of one event **3**.
- **A failed run leaves the agent enabled.** Nothing but an admin disables an agent, and an agent disables nothing.

### What the platform's harness does with an event

The harness asks the document's model with the agent's instructions, the trigger's instructions, what happened, and one definition per tool; runs each call the model asks for, one at a time, in the model's order; gives each result back as the tool's turn; and asks again until the model asks for nothing. That text is the answer, and the run ends `done`. Its rules:

- **A turn identical to the previous one is not run**, checked **before** its calls are executed — a model that has finished sometimes repeats its closing turn with the calls it already made attached, and a repeated call may be a write. The run ends `done` with the model's words.
- **A failed call is given back in the tool's own words** — a refusal, a toolkit's error, a store's refusal — and the run goes on; the model decides what to do with it.
- **Every turn is written as it happens** to the agent's namespace in the `agents` store, so the agent's page shows it, and a second handing-over continues from what was written.
- **Every run starts fresh.** The harness carries nothing from one run to the next.

The tools the model sees are exactly these — write your instructions with them in mind:

| Tools | How the model sees them |
|---|---|
| each tool of each toolkit in `toolkits` | `<toolkit>__<tool>`, with the toolkit's own description and schema, unchanged |
| the state tools, for each store in `stores` | `state_get`, `state_list`, `state_history`, and `state_apply` where the store is marked `write`; the store's name is a parameter, and an operation's body is the store's type's |
| the agent's notes | `note_write`, `note_read` — a key and a text, kept under the agent's namespace in the `agents` store across runs; this is the one way an agent remembers |

### A call a rule escalates

When a workspace rule escalates one of the agent's calls, the call is **refused** at the enforcement point with the escalation's id, as for anyone. For a run that is the agent's own, the crossing is addressed to the workspace's **admins** whatever the rule's approver says — there is nobody else to ask — and shows on Approvals naming the agent and the run; the agent's page shows **waiting for approval**. The run goes on without the result: the model is told *refused; an admin has been asked*, and the run ends as it ends. When an admin **grants** it, the agent issues the kept call again exactly, and the result arrives as a **new event of the same trigger** — *the call you were refused was approved and ran; this is its result* — which opens a new run. Denied or expired: an event saying so, the same way. The agent approves nothing and holds no grant.

In a run that acts **for its caller**, the crossing is the caller's, addressed as the rule says, and the reply ends with the refusal and the escalation id; the caller decides it where they are and sends again.

## Adding, operating, deleting

**Add an agent** (the console's form, or `impire agents add <file>` with the document) composes, in this order: the workload's registration on the platform's agent image, with the agent's name, one replica and no egress; the workspace's **`agents` store, once** — where none exists yet it is created, scoped by workload, with the record's four types; every add after the first finds it there and shows the step as *there*; then the document. Nothing is created per agent but its registration and its document — there is no store per agent, no owner. A failure midway is shown where it happened and **what was created stays** — an agent the table shows *not configured*. Save again, or `agents add` again with the same name, **completes what is missing**: the console reads before it writes and creates nothing twice. Nothing is rolled back. An agent **is not ready** until the `agents` store, its four types and the agent's document are all there — a workspace whose `agents` store is missing shows every agent *not configured*, saying so.

**The registration** is the platform's: the agent image, pinned by the install and followed when the install moves it; one replica; **no egress** — the agent reaches the bus and nothing else, and an external system is a toolkit's to reach; the install's default resources or what the admin chose. An agent counts against the workspace's workload, vCPU and memory limits as one workload and is no plan feature of its own.

**The status word**, one per agent, the first that holds:

| Word | Means |
|---|---|
| **stopped** | the registration is suspended: nothing runs, nothing fires |
| **not configured** | the document is absent or refused; the agent is up and does nothing until it holds one — the reason is shown |
| **paused** | the hour's ceiling of runs was reached; the agent holds events until an admin stops and starts it |
| **waiting for approval** | a crossing the agent caused is open on Approvals |
| **working** | a run is open |
| **idle** | the placement runs with no run open |

A member sees the agents that are up as *available*; a stopped or not-yet-configured agent is not on a member's page.

**Stop** and **Start** (`impire agents suspend <agent>`, `impire agents resume <agent>`) are the workload's emergency stop and its reversal. **Stop** destroys the placement: an open run is closed `stopped` and not taken up again, the agent's schedules end, its subject messages stop being delivered, and nothing is kept for it while it is stopped. **Start** boots it: it reads its document and its cursors, declares what it listens for, and **catches up once** — each instance that changed under a watched path while it was away, once, in its state now; each schedule from its next time, never for the times missed; nothing of the messages published on its subjects meanwhile. Stop and start is also how an admin lifts a pause.

**Delete** (`impire agents delete <agent>`, which asks unless told not to) retires the registration and deletes the document; **nothing in the `agents` store is deleted** — *its runs and notes stay under the retired id, readable by admins and written by nobody; the calls it made stay in the workspace's records*. The registration stays, retired, so the records keep their attribution. A store's size is what bounds the record of retired agents; an admin who needs the room raises the store's sizes or compacts it, as with any store.

**The terminal client's group**, verb by verb — `impire agents <verb> -h` for the flags:

- `agents list` — a member's list, from discovery; `--everyone` for an admin's table with the statuses.
- `agents add <file>` — the document from a file; prints the workload id; finishes a half-made agent when run again.
- `agents get <agent>` — the registration's status, the document, the triggers with when each last fired.
- `agents set <agent> <file>` — replace the document.
- `agents runs <agent>`, `agents run <agent> <run>` — an admin's: the runs, newest first; one run with its turns; `--follow` on an open run. A member has no namespace in `agents` and is offered neither.
- `agents send <agent> <trigger> <text>` — a request; the reply's frames to standard output as they arrive.
- `agents fire <agent> <trigger> [<file>]` — fire a state, subject or schedule trigger by hand.
- `agents suspend <agent>`, `agents resume <agent>` — stop, start.
- `agents delete <agent>` — asks, unless `--yes`.

`<agent>` is the name; the client resolves it to the workload id.

## The record

All of a workspace's agents keep their records in **one store, `agents`** — created once, by whichever admin adds the first agent, with four types, and never per agent. It is a **scoped store**, scoped by workload: every path in it begins with a **namespace**, the agent's workload id, and the agent never writes that namespace — it writes `run/<run>`, `run/<run>/turn/<n>`, `cursor/<trigger>` and `note/<key>`, and the state service prefixes the namespace it reads from the agent's own verified identity, so the store holds `<id>/run/<run>`. An agent can address no namespace but its own: the plain store verbs are always the caller's own namespace, and a list answers only it. The workspace's **admins** read every namespace — the agent's page and `impire agents runs` / `run` are such reads — on a read-only family of verbs their template alone admits. A **member** and every **workload that is not an agent** reach nothing in `agents`. No tag is written on anyone's connection, no connection is kicked when an agent is added, and the state service checks nothing by role: who may reach what is the broker's allow lists plus one rule — the namespace is the caller's identity.

The four types: `run/<run>` — the trigger and its kind, the event or its digest, who sent it where someone did, whom the run acts for, when it opened and ended and how, how often it was handed over, whether an admin fired it by hand, and each kept call while its crossing is open; `run/<run>/turn/<n>` — the model's text, each call with its arguments, each result, in order; `cursor/<trigger>` — where each state trigger has read to and when each schedule last fired; `note/<key>` — what the model chose to remember.

The record the workspace **always** has, whatever the harness, is the calls: every model asked and every tool called is in the workspace's own records under the agent's name, as every workload's calls are. The `agents` store is never one of the stores an agent watches, and it declares no index: a scoped store has none, so there is no search across the record — an admin browses it one namespace at a time (the console's Stores page lists the namespaces; `impire stores namespaces agents`, and `--namespace <id>` on the items commands, do the same in the terminal).

## Stores, as far as agents touch them

- **A store is regular or scoped.** A regular store is the workspace's — every member and workload reads and writes it, and it is what an agent's `stores` list names. A scoped store (`workload` or `person`) gives every caller a namespace of its own, judged from the caller's identity; `agents` is the one the platform makes. An admin creates either kind; the scope is fixed at creation.
- **A store reserves two sizes and shows two fills.** Its **size** caps the log — the history of changes; its **state size** caps the current state kept beside it — the log's size when none is named. Both are reserved against the workspace's room the moment the store is made, and the console and `impire stores list` / `get` show *log* and *state* fills apart, each with its own *near full* and *full*. A full log refuses new changes; a full state stops the fold — the index lags, which every reply says — and refuses new changes naming the state size to raise. Flags: `impire stores <verb> -h`.
- **For developers using the SDKs**: every reply of the state family carries `Impire-State-Folded`, the sequence the store's index has reached, so a reader can see how far behind the log it is; `get`, `list` and `watch` take `Impire-State-Min-Seq` and are answered once the index has reached that sequence, or refused `timeout` naming where it stood; a write (`apply`) is answered once its own change is folded, so the writer's next read is exact. A scoped store refuses `index.declare` and `index.query`. The admin's cross-namespace reads are the `scoped` family — `state.scoped.get`, `history`, `watch`, `list` and `namespaces` — with client methods of the same names in both SDKs.

## Writing good instructions

- **The agent's `instructions` are its standing orders; a trigger's `instructions` are the handler.** Both are handed to the model with every event, so say in the trigger's text what to do with *this* kind of event, and in the agent's text who it is, which stores and toolkits it works with, and what it must never do.
- **Name the stores and tools by the names the model sees** — `orders` for the store, `mail__send` for the tool — and say when to read before writing: an agent that writes to a store it watches does not fire itself, so a status change is safe.
- **Say what to remember.** `note_write` is the agent's only memory across runs. Tell it which notes to keep and under which keys, or it will keep none.
- **Expect a fresh start and a bounded run.** Fifty model requests and fifteen minutes by reference; an agent asked to do a large job should write progress to a store and let the next event continue.
- **Put the boundary in rules, not in prose.** An agent acting as itself is governed by rules written about the agent; a rule that escalates a tool asks an admin and the agent is told it was refused. Prose that says *never send mail without asking* is a wish; a rule is a guarantee.
- **Prefer narrow triggers.** `operations: [created]` and a `path` over the whole store; a subject over a wildcard; a weekday cron in the workspace's zone over `every`.

## What agents do not do, in this increment

Do not promise these: a **brought harness** (your own harness image handed the events — the boundary is drawn, the second increment fills it); **sleep** between events (an agent stays awake and holds its microVM); **memory** or **knowledge** beyond notes and stores; a **source** — a webhook or a mailbox that publishes onto `event.>`; a **link of the agent's own** at an upstream (person-scoped toolkits answer an agent acting as itself as they answer anyone without a link); an **agent as a model** on the gateway's faces or in the chat's picker; **orchestration across agents** (an agent may send another a request; nothing above them plans or hands off); **several replicas**, and so several runs at once; a **conversation** with an agent (a request is one request and its reply); **renaming** an agent; a **marketplace of agents** (an agent a workspace installs ready-made is a solution's workload).

## For developers

The SDKs carry the agent's contract so that a client or a tool can speak it without restating it: the document's shape and its validation, the reserved trigger names, the `agents` store's name and the record's four types in the order a surface defines them, the record's path helpers (which take no namespace — the service prefixes it), how a run's id and a schedule's due time are derived, and the fire-by-hand subject — the `agent` package of `impire-sdk-go` and the `agent` module of `impire-sdk-js`; the store's scope, its two sizes and fills, the fold headers and the `scoped` family are in their `state` packages. Read those for signatures; this skill states only the semantics they implement.

## Sources

Derived from the Impire hq's design, which is authoritative where this skill and the platform disagree: `02-DESIGN/22-agents/01-the-agent.md` (the agent, the document, whom it acts as, the store, enabled and disabled), `02-triggers.md` (the four kinds, catching up, firing by hand), `03-a-run.md` (a run, the harness, the bounds, escalations, the record), `04-the-agents-surface.md` (the page, the form, the statuses, the verbs), `02-DESIGN/10-state/01-stores-types-and-instances.md` (regular and scoped stores, the size and the state size, who may do what), and decisions `0091`, `0093` and `0094`. See `DERIVATION.md` at the repo root.
