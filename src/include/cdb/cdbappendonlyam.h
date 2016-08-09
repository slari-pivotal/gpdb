/*-------------------------------------------------------------------------
 *
 * appendonlyam.h
 *	  append-only relation access method definitions.
 *
 *
 * Portions Copyright (c) 1996-2006, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 * Portions Copyright (c) 2007, Greenplum Inc.
 *
 *-------------------------------------------------------------------------
 */
#ifndef APPENDONLYAM_H
#define APPENDONLYAM_H

#include "access/htup.h"
#include "access/relscan.h"
#include "access/sdir.h"
#include "access/tupmacs.h"
#include "access/xlogutils.h"
#include "access/appendonly_visimap.h"
#include "executor/tuptable.h"
#include "nodes/primnodes.h"
#include "nodes/bitmapset.h"
#include "storage/block.h"
#include "storage/lmgr.h"
#include "utils/rel.h"
#include "utils/tqual.h"
#include "storage/gp_compress.h"

#include "access/appendonlytid.h"

#include "cdb/cdbvarblock.h"
#include "cdb/cdbbufferedappend.h"
#include "cdb/cdbbufferedread.h"
#include "cdb/cdbvarblock.h"

#include "cdb/cdbappendonlystoragelayer.h"
#include "cdb/cdbappendonlystorageread.h"
#include "cdb/cdbappendonlystoragewrite.h"
#include "cdb/cdbappendonlyblockdirectory.h"

#define DEFAULT_COMPRESS_LEVEL				 0
#define MIN_APPENDONLY_BLOCK_SIZE			 8 * 1024
#define DEFAULT_APPENDONLY_BLOCK_SIZE		32 * 1024
#define MAX_APPENDONLY_BLOCK_SIZE			 2 * 1024 * 1024
#define DEFAULT_VARBLOCK_TEMPSPACE_LEN   	 4 * 1024 
#define DEFAULT_FS_SAFE_WRITE_SIZE			 0

/*
 * AppendOnlyInsertDescData is used for inserting data into append-only
 * relations. It serves an equivalent purpose as AppendOnlyScanDescData
 * (relscan.h) only that the later is used for scanning append-only 
 * relations. 
 */
typedef struct AppendOnlyInsertDescData
{
	Relation		aoi_rel;
	Snapshot		appendOnlyMetaDataSnapshot;
	MemTupleBinding *mt_bind;
	File			appendFile;
	int				appendFilePathNameMaxLen;
	char			*appendFilePathName;
	float8			insertCount;
	float8			varblockCount;
	int64           rowCount; /* total row count before insert */
	int64           numSequences; /* total number of available sequences */
	int64           lastSequence; /* last used sequence */
	BlockNumber		cur_segno;
	AppendOnlyEntry *aoEntry;
	FileSegInfo     *fsInfo;
	VarBlockMaker	varBlockMaker;
	int64			bufferCount;
	int64			blockFirstRowNum;
	bool			shouldCompress;
	bool			usingChecksum;
	bool			useNoToast;
	int32			completeHeaderLen;
	uint8			*tempSpace;
	uint8			*uncompressedBuffer; /* used for compression */

	int32			usableBlockSize;
	int32			maxDataLen;
	int32			tempSpaceLen;

	char						*title;
				/*
				 * A phrase that better describes the purpose of the this open.
				 *
				 * We manage the storage for this.
				 */

	/*
	 * These serve the equivalent purpose of the uppercase constants of the same
	 * name in tuptoaster.h but here we make these values dynamic.
	 */	
	int32			toast_tuple_threshold;
	int32			toast_tuple_target;
	AppendOnlyStorageAttributes storageAttributes;
	AppendOnlyStorageWrite		storageWrite;

	uint8			*nonCompressedData;

	/* The block directory for the appendonly relation. */
	AppendOnlyBlockDirectory blockDirectory;

	bool update_mode;
} AppendOnlyInsertDescData;

typedef AppendOnlyInsertDescData *AppendOnlyInsertDesc;

typedef struct AppendOnlyExecutorReadBlock
{
	MemoryContext	memoryContext;

	AppendOnlyStorageRead	*storageRead;

	int				segmentFileNum;

	int64			totalRowsScannned;

	int64			blockFirstRowNum;
	int64			headerOffsetInFile;
	uint8			*dataBuffer;
	int32			dataLen;
	int 			executorBlockKind;
	int 			rowCount;
	bool			isLarge;
	bool			isCompressed;

	uint8			*uncompressedBuffer; /* for decompression */

	uint8			*largeContentBuffer;
	int32			largeContentBufferLen;

	VarBlockReader  varBlockReader;
	int				readerItemCount;
	int				currentItemCount;
	
	uint8			*singleRow;
	int32			singleRowLen;

	/* synthetic system attributes */
	ItemPointerData cdb_fake_ctid;
	MemTupleBinding *mt_bind;
} AppendOnlyExecutorReadBlock;

/*
 * used for scan of append only relations using BufferedRead and VarBlocks
 */
typedef struct AppendOnlyScanDescData
{
	/* scan parameters */
	Relation	aos_rd;				/* target relation descriptor */
	Snapshot	appendOnlyMetaDataSnapshot;

	/*
	 * Snapshot to use for non-metadata operations.
	 * Usually snapshot = appendOnlyMetaDataSnapshot, but they
	 * differ e.g. if gp_select_invisible is set.
	 */ 
	Snapshot    snapshot;

	Index       aos_scanrelid;
	int			aos_nkeys;			/* number of scan keys */
	ScanKey		aos_key;			/* array of scan key descriptors */
	bool		aos_notoast;		/* using toast for this relation? */
	
	/* file segment scan state */
	int			aos_filenamepath_maxlen;
	char		*aos_filenamepath;
									/* the current segment file pathname. */
	int			aos_total_segfiles;	/* the relation file segment number */
	int			aos_segfiles_processed; /* num of segfiles already processed */
	FileSegInfo **aos_segfile_arr;	/* array of all segfiles information */
	bool		aos_need_new_segfile;
	bool		aos_done_all_segfiles;
	
	MemoryContext	aoScanInitContext; /* mem context at init time */

	int32			usableBlockSize;
	int32			maxDataLen;

	AppendOnlyExecutorReadBlock	executorReadBlock;

	/* current scan state */
	bool		bufferDone;

	bool	initedStorageRoutines;

	AppendOnlyStorageAttributes	storageAttributes;
	AppendOnlyStorageRead		storageRead;

	char						*title;
				/*
				 * A phrase that better describes the purpose of the this open.
				 *
				 * We manage the storage for this.
				 */

	AppendOnlyEntry		*aoEntry;
	
	/*
	 * The block directory info.
	 *
	 * For AO tables that are upgraded from pre-3.4 release, the block directory 
	 * built during the first index creation.
	 */
	bool buildBlockDirectory; /* Indicate whether to build block directory while scanning */
	AppendOnlyBlockDirectory *blockDirectory;

	/**
	 * The visibility map is used during scans
	 * to check tuple visibility using visi map.
	 */ 
	AppendOnlyVisimap visibilityMap;

}	AppendOnlyScanDescData;

typedef AppendOnlyScanDescData *AppendOnlyScanDesc;

/*
 * Statistics on the latest fetch.
 */
typedef struct AppendOnlyFetchDetail
{
	int64		rangeFileOffset;
	int64		rangeFirstRowNum;
	int64		rangeAfterFileOffset;
	int64		rangeLastRowNum;
					/*
					 * The range covered by the Block Directory.
					 */
	
	int64		skipBlockCount;
					/*
					 * Number of blocks skipped since the previous block processed in
					 * the range.
					 */
	
	int64		blockFileOffset;
	int32		blockOverallLen;
	int64		blockFirstRowNum;
	int64		blockLastRowNum;
	bool		isCompressed;
	bool		isLargeContent;
					/*
					 * The last block processed.
					 */

} AppendOnlyFetchDetail;


/*
 * Used for fetch individual tuples from specified by TID of append only relations 
 * using the AO Block Directory, BufferedRead and VarBlocks
 */
typedef struct AppendOnlyFetchDescData
{
	Relation		relation;
	Snapshot		appendOnlyMetaDataSnapshot;

	/*
	 * Snapshot to use for non-metadata operations.
	 * Usually snapshot = appendOnlyMetaDataSnapshot, but they
	 * differ e.g. if gp_select_invisible is set.
	 */ 
	Snapshot    snapshot;

	MemoryContext	initContext;

	AppendOnlyStorageAttributes	storageAttributes;
	AppendOnlyStorageRead		storageRead;

	char						*title;
				/*
				 * A phrase that better describes the purpose of the this open.
				 *
				 * We manage the storage for this.
				 */


	int				totalSegfiles;
	FileSegInfo 	**segmentFileInfo;

	AppendOnlyEntry *aoEntry;

	char			*segmentFileName;
	int				segmentFileNameMaxLen;

	int32			usableBlockSize;

	AppendOnlyBlockDirectory	blockDirectory;

	AppendOnlyExecutorReadBlock executorReadBlock;

	CurrentSegmentFile currentSegmentFile;
	
	int64		scanNextFileOffset;
	int64		scanNextRowNum;

	int64		scanAfterFileOffset;
	int64		scanLastRowNum;

	CurrentBlock currentBlock;

	int64	skipBlockCount;

	AppendOnlyVisimap visibilityMap;

}	AppendOnlyFetchDescData;

typedef AppendOnlyFetchDescData *AppendOnlyFetchDesc;

typedef struct AppendOnlyUpdateDescData *AppendOnlyUpdateDesc;
typedef struct AppendOnlyDeleteDescData *AppendOnlyDeleteDesc;


/* ----------------
 *		function prototypes for appendonly access method
 * ----------------
 */

extern AppendOnlyScanDesc appendonly_beginscan(Relation relation,
											   Snapshot snapshot,
											   Snapshot appendOnlyMetaDataSnapshot,
											   int nkeys, 
											   ScanKey key);
extern AppendOnlyScanDesc appendonly_beginrangescan(Relation relation, 
		Snapshot snapshot,
		Snapshot appendOnlyMetaDataSnapshot, 
		int *segfile_no_arr, int segfile_count,
		int nkeys, ScanKey keys);
extern void appendonly_rescan(AppendOnlyScanDesc scan, ScanKey key);
extern void appendonly_endscan(AppendOnlyScanDesc scan);
extern MemTuple appendonly_getnext(AppendOnlyScanDesc scan, 
									ScanDirection direction,
									TupleTableSlot *slot);
extern AppendOnlyFetchDesc appendonly_fetch_init(
	Relation 	relation,
	Snapshot    snapshot,
	Snapshot 	appendOnlyMetaDataSnapshot);
extern bool appendonly_fetch(
	AppendOnlyFetchDesc aoFetchDesc,
	AOTupleId *aoTid,
	TupleTableSlot *slot);
extern void appendonly_fetch_detail(
	AppendOnlyFetchDesc aoFetchDesc, 
	AppendOnlyFetchDetail *aoFetchDetail);
extern void appendonly_fetch_finish(AppendOnlyFetchDesc aoFetchDesc);
extern AppendOnlyInsertDesc appendonly_insert_init(Relation rel, int segno, bool update_mode);
extern void appendonly_insert(
		AppendOnlyInsertDesc aoInsertDesc, 
		MemTuple instup, 
		Oid *tupleOid, 
		AOTupleId *aoTupleId);
extern void appendonly_insert_finish(AppendOnlyInsertDesc aoInsertDesc);
extern BlockNumber RelationGuessNumberOfBlocks(double totalbytes);

extern AppendOnlyDeleteDesc appendonly_delete_init(Relation rel, Snapshot appendOnlyMetaDataSnapshot);
extern HTSU_Result appendonly_delete(
		AppendOnlyDeleteDesc aoDeleteDesc,
		AOTupleId* aoTupleId);
extern void appendonly_delete_finish(AppendOnlyDeleteDesc aoDeleteDesc);

extern AppendOnlyUpdateDesc appendonly_update_init(Relation rel, Snapshot appendOnlyMetaDataSnapshot, int segno);
extern HTSU_Result appendonly_update(
		AppendOnlyUpdateDesc aoUpdateDesc,
		MemTuple memTuple,
		AOTupleId* aoTupleId,
		AOTupleId* newAoTupleId);
extern void appendonly_update_finish(AppendOnlyUpdateDesc aoUpdateDesc);
#endif   /* APPENDONLYAM_H */
