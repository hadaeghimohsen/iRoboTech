SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[ShrinkLogFileDb]	
AS
BEGIN
	
   ALTER DATABASE iRoboTech SET RECOVERY SIMPLE;
   DBCC SHRINKFILE(N'iRoboTech_log', 1);
   ALTER DATABASE iRoboTech SET RECOVERY FULL;
   PRINT 'iRoboTech Log File Shrink 1 MB';
   	
END
GO
