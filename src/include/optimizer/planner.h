/*-------------------------------------------------------------------------
 *
 * planner.h
 *	  prototypes for planner.c.
 *
 *
 * Portions Copyright (c) 1996-2012, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/optimizer/planner.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PLANNER_H
#define PLANNER_H

#include "nodes/plannodes.h"
#include "nodes/relation.h"
#include "optimizer/clauses.h"


/* Hook for plugins to get control in planner() */
typedef PlannedStmt *(*planner_hook_type) (Query *parse,
													   int cursorOptions,
												  ParamListInfo boundParams);
extern PGDLLIMPORT planner_hook_type planner_hook;


extern PlannedStmt *planner(Query *parse, int cursorOptions,
		ParamListInfo boundParams);
extern PlannedStmt *standard_planner(Query *parse, int cursorOptions,
				 ParamListInfo boundParams);

extern Plan *subquery_planner(PlannerGlobal *glob, Query *parse,
				 PlannerInfo *parent_root,
				 bool hasRecursion,
				 double tuple_fraction,
				 PlannerInfo **subroot,
				 PlannerConfig *config);

extern bool choose_hashed_grouping(PlannerInfo *root,
								   double tuple_fraction, double limit_tuples,
								   double path_rows, int path_width,
								   Path *cheapest_path,
								   Path *sorted_path,
								   int numGroupOps,
								   double dNumGroups,
								   AggClauseCosts *agg_costs);

extern bool is_dummy_plan(Plan *plan);

extern Expr *expression_planner(Expr *expr);

extern bool plan_cluster_use_sort(Oid tableOid, Oid indexOid);

#endif   /* PLANNER_H */
