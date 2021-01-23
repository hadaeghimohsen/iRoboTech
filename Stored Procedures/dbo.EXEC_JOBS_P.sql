SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXEC_JOBS_P]	
   @X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN [T$EXEC_JOBS_P]
	   DECLARE C$ActvRobo CURSOR FOR
	      SELECT r.RBID, r.CNCT_ACNT_APP, r.ACNT_APP_TYPE
	        FROM dbo.Robot r, dbo.Organ o
	       WHERE r.ORGN_OGID = o.OGID
	         AND o.STAT = '002'
	         AND r.STAT = '002'
	         AND r.RUN_STAT = '002';
   	
	   DECLARE @Rbid BIGINT
	          ,@CnctAcntApp VARCHAR(3)
	          ,@AcntAppType VARCHAR(3);
   	
	   OPEN [C$ActvRobo];
	   L$Loop1:
	   FETCH [C$ActvRobo] INTO @Rbid, @CnctAcntApp, @AcntAppType;
   	
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop1;
   	
   	-- Step . عملیاتی که برای اتصال نرم افزار حسابداری باید انجام شود
   	IF @CnctAcntApp = '002' -- اتصال برقرار باشد
   	   IF @AcntAppType = '001' -- نرم افزار مدیریتی آرتا
   	   BEGIN
   	      -- گام اول بروزرسانی محصولات جدید اضافه شده
   	      INSERT INTO dbo.Robot_Product
            (ROBO_RBID ,CODE ,TARF_CODE ,PROD_FETR )
            SELECT @Rbid, dbo.GNRT_NVID_U(), e.ORDR_ITEM, e.EXPN_DESC
              FROM iScsc.dbo.Expense e, iScsc.dbo.Expense_Type et, 
                   iScsc.dbo.Request_Requester rr, iScsc.dbo.Regulation r
             WHERE e.EXTP_CODE = et.CODE
               AND et.RQRQ_CODE = rr.CODE
               AND rr.RQTP_CODE = '016'
               AND rr.RQTT_CODE = '001'
               AND rr.REGL_YEAR = r.YEAR
               AND rr.REGL_CODE = r.CODE
               AND r.REGL_STAT = '002'
               AND r.[TYPE] = '001'
               AND e.EXPN_STAT = '002'
               AND e.ORDR_ITEM IS NOT NULL
               AND NOT EXISTS(
                  SELECT *
                    FROM dbo.Robot_Product rp
                   WHERE rp.TARF_CODE = e.ORDR_ITEM
                     AND rp.ROBO_RBID = @Rbid
               );   	      
   	   END
   	
	   GOTO L$Loop1;
	   L$EndLoop1:
	   CLOSE [C$ActvRobo];
	   DEALLOCATE [C$ActvRobo];  
	 	
	COMMIT TRAN [T$EXEC_JOBS_P];
	END TRY
	BEGIN CATCH
	
	END CATCH
END
GO
