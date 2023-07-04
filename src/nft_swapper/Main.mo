import Types "Types";

actor class () {
  // to do:
  //
  // stable var map from PlanId to Plan.
  //
  // submitPlan -- creates a new PlanId, or returns the same one for the same Plan.
  //               (hack idea: use to_candid + Blob.hash to hash the Plan without much new programming.)
  //
  // notifyPlan -- permits Alice and Bob to notify the Plan that they've committed their owned resources to the plan.
  //               these claims are verified by notifyPlan, and if Alice or Bob lie, the Plan becomes invalid.
  //               if all notifications do not arrive in the Plan's timeWindow, it can time out.
  //
  // (refreshPlan -- permits Alice and Bob to send a "heartbeat" update message to the Plan, to refresh its state with
  //                respect to the time out, and transition a plan in state Resourcing into a plan in state TimeOut.)
  //
  // pollPlan -- permits Alice and Bob to query the plan state,
  //             e.g., to see whether the other is done committing resources, or not.
  //             (freshPlan is the same, but as an update call that saves the new state for future polling.)
  //

};
