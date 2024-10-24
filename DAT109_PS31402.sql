--Restore Database SAMPLE 
use [master]
RESTORE DATABASE [SAMPLE] 
FROM DISK = N'H:\DU PHONG\SAMPLE.bak' WITH FILE =1,
	MOVE N'SAMPLE' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SAMPLE.mdf',
	MOVE N'SAMPLE_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SAMPLE_log.ldf',
	NOUNLOAD,
	REPLACE,
	STATS = 5;
GO


----COPY DATABASE SAMPLE DAT TEN DATABASE LA STAGING
----RESTORE DATABASE STAGING

DECLARE @backupPath nvarchar(400);
DECLARE @sourceDb nvarchar(50);
DECLARE @sourceDb_log nvarchar(50);
DECLARE @destDb nvarchar(100);
DECLARE @destMdf nvarchar(100);
DECLARE @destLdf nvarchar(100);
DECLARE @sqlServerDbFolder nvarchar(100);


SET @sourceDb = 'SAMPLE'
SET @sourceDb_log = @sourceDb + '_log'
set @backupPath = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\' + @sourceDb +'.bak'
set @sqlServerDbFolder = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\'
SET @destDb = 'Staging'
set @destMdf = @sqlServerDbFolder + @destDb + '.mdf'
set @destLdf = @sqlServerDbFolder + @destDb + '_log' + '.ldf'

backup database @sourceDb TO DISK = @backupPath

RESTORE DATABASE @destDb FROM DISK = @backupPath
with replace,
	move @sourceDb		to @destMdf,
	move @sourceDb_log	to @destLdf



---lam sach DATABASE(GIAODICH_CLEAN_1)
SELECT ROW_NUMBER() OVER (ORDER BY MaCK ASC) AS ID, *
	INTO [Staging].[dbo].[GIAODICH_CLEAN_1]
FROM [Staging].[dbo] .[GIAODICH]
WHERE [KHOILUONGGIAODICH] >0 AND ISDATE([NGAYGIAODICH]) > 0; 
---TRONG DO WHERE LA DIEU KIEN DE LOC DU LIEU [KHOILUONGGIAODICH] >0 VA [NGAYGIAODICH] > 0





---lam sach DATABASE(GIAODICH_CLEAN_2)
SELECT *INTO [Staging].[dbo].[GIAODICH_CLEAN_2]
FROM
(
	SELECT *
		, DuplicateRow = ROW_NUMBER() OVER
	(
		PARTITION BY
		[MaCK]
		,[NGAYGIAODICH]
		,[GIAMOCUA]
		,[GIACAONHAT]
		,[GIATHAPNHAT]
		,[GIADONGCUA]
		,[KHOILUONGGIAODICH]
	ORDER BY (SELECT NULL)
	)
	FROM [Staging].[dbo].[GIAODICH_CLEAN_1]
)TEMP
WHERE TEMP.DuplicateRow = 1 



---CLEAN_FINAL
SELECT 
	[ID]
	,[MaCK]
	,FORMAT(CONVERT(datetime, [NGAYGIAODICH]), 'd', 'us') as [NGAYGIAODICH]
	,[GIAMOCUA]
	,[GIACAONHAT]
	,[GIATHAPNHAT]
	,[GIADONGCUA]
	,[KHOILUONGGIAODICH]
	,FORMAT([GIAMOCUA]*(1+[BIENDODAODONG]), 'F', 'en-us') as GIATRAN
	,FORMAT([GIAMOCUA]*(1-[BIENDODAODONG]), 'F', 'en-us') as GIASAN
	,FORMAT(([GIADONGCUA]-[GIAMOCUA])*100/[GIAMOCUA], 'F', 'en-us') AS TILETRONGNGAY
	,[TENNHOMNGANH]
	,[MANHOMNGANH]
	,[THONGTINCONGTY]
	,[SAN]
	,[CONGTY]
	,[TENSAN_VIET]
	,[TENSAN_ANH]
	,[BIENDODAODONG]
	,[DuplicateRow]
INTO [Staging].[dbo].[GIAODICH_FINAL]
FROM [Staging].[dbo].[GIAODICH_CLEAN_2]


---COPY DATABASE STAGING THANH DATABASE SPEND VA KET NOI VOI POWER BI DESKTOP CHUAN BI CHO BUOC CHUAN HOA VA TAO BAO CAO