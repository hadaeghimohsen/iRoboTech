SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MNGR_CRDT_P]
	-- Add the parameters for the stored procedure here
	@X XML, 
	@xRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$MNGR_CRDT_P]
	
	DECLARE @Rbid BIGINT
	       ,@SubSys INT
	       ,@CrdtType VARCHAR(3)
	       ,@MainActnCode VARCHAR(3)
	       ,@SubActnCode VARCHAR(3)
	       ,@FromDate DATE
	       ,@ToDate DATE;
	
	SELECT @Rbid = @X.query('//Robot').value('(Robot/@rbid)[1]', 'BIGINT')
	      ,@SubSys = @X.query('//Robot').value('(Robot/@subsys)[1]', 'INT')
	      ,@CrdtType = @X.query('//Credit').value('(Credit/@type)[1]', 'VARCHAR(3)')
	      ,@MainActnCode = @X.query('//Credit').value('(Credit/@mainactncode)[1]', 'VARCHAR(3)')
	      ,@SubActnCode = @X.query('//Credit').value('(Credit/@subactncode)[1]', 'VARCHAR(3)')
	      ,@FromDate = @X.query('//Credit').value('(Credit/@fromdate)[1]', 'DATE')
	      ,@ToDate = @X.query('//Credit').value('(Credit/@todate)[1]', 'DATE')
	
	-- نمایش موجودی اعتبار
	IF @MainActnCode = '001'
	BEGIN
	   SET @xRet = (
         SELECT CASE @CrdtType
                     WHEN '013' THEN N'⏳ نمایش موجودی 💳 شارژ کارمزد پرداخت'
                     WHEN '014' THEN N'⏳ نمایش موجودی 💳 شارژ خدمات شبکه های اجتماعی'
                END + CHAR(10) + CHAR(10) +
                N'👈 [ موجودی حساب ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, ISNULL(rc.CRDT_AMNT_DNRM, 0)), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
                CASE WHEN rc.LAST_DPST_CRDT_AMNT_DNRM IS NOT NULL THEN
                   CHAR(10) + 
                   N'📑 [ آخرین شارژ انجام شده ] ' + CHAR(10) + 
                   N'👈 [ مبلغ شارژ ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, ISNULL(rc.LAST_DPST_CRDT_AMNT_DNRM, 0)), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) +
                   N'👈 [ تاریخ شارژ ] *' + dbo.GET_MTOS_U(rc.LAST_DPST_CRDT_DATE_DNRM) + N'*' + CHAR(10) 
                ELSE N' '
                END 
           FROM dbo.Robot_Credit rc, dbo.[D$AMUT] au
          WHERE rc.ROBO_RBID = @Rbid
            AND rc.SUB_SYS = @SubSys
            AND rc.CRDT_TYPE = @CrdtType
            AND rc.AMNT_TYPE = au.VALU
        FOR XML PATH('Message'), ROOT('Result')	        
      );
	END -- IF @MainActnCode = '001'	
	-- گزارشات
	ELSE IF @MainActnCode = '002'	
	BEGIN
	   -- گزارش شارژ
	   IF @SubActnCode = '001'
	   BEGIN
	      IF EXISTS (SELECT * FROM dbo.Robot_Credit rc, dbo.Robot_Credit_Detial rcd WHERE rc.ROBO_RBID = @Rbid AND rc.SUB_SYS = @SubSys AND rc.CRDT_TYPE = @CrdtType AND rc.CRID = rcd.RCRD_CRID AND CAST(rcd.CRDT_DATE AS DATE) BETWEEN @FromDate AND @ToDate AND rcd.VALD_TYPE = '002')
	      BEGIN	      
	         SET @xRet = (
               SELECT CASE @CrdtType
                           WHEN '013' THEN N'⏳ گزارش افزایش 💳 شارژ کارمزد پرداخت'
                           WHEN '014' THEN N'⏳ گزارش افزایش 💳 شارژ خدمات پس از فروش'
                      END  + CHAR(10) + CHAR(10) +
                      CASE 
                        WHEN @FromDate = @todate THEN N'تاریخ گزارش [ *امروز* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 1 AND 7 THEN N'تاریخ گزارش [ *این هفته* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 8 AND 30 THEN N'تاریخ گزارش [ *این ماه* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 31 AND 365 THEN N'تاریخ گزارش [ *امسال* ]'
                        ELSE N'از تاریخ *' + dbo.GET_MTOS_U(@FromDate) + N'* تا تاریخ *' + dbo.GET_MTOS_U(@ToDate) + N'* *' + CAST(DATEDIFF(DAY, @FromDate, @ToDate) AS NVARCHAR(10)) + N'*'
                      END + CHAR(10) + CHAR(10) +
                      N'👈   [ مبلغ شارژ ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM(ISNULL(rcd.CRDT_AMNT, 0))), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) +
                      N'👈   [ تعداد دفعات شارژ ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(rcd.CDID)), 1), '.00', '') + N'* [ *بار* ]' + CHAR(10) 
                 FROM dbo.Robot_Credit rc, dbo.Robot_Credit_Detial rcd, dbo.[D$AMUT] au
                WHERE rc.ROBO_RBID = @Rbid
                  AND rc.SUB_SYS = @SubSys
                  AND rc.CRDT_TYPE = @CrdtType
                  AND rc.CRID = rcd.RCRD_CRID
                  AND rcd.AMNT_TYPE = au.VALU
                  AND CAST(rcd.CRDT_DATE AS DATE) BETWEEN @FromDate AND @ToDate
                  AND rcd.VALD_TYPE = '002'
                GROUP BY au.DOMN_DESC
              FOR XML PATH('Message'), ROOT('Result')	           
            ); 
         END
         ELSE
            SET @xRet = (
               SELECT CASE @CrdtType
                           WHEN '013' THEN N'⚠️ داده ای برای نمایش گزارش [ *افزایش 💳 شارژ کارمزد پرداخت* ] وجود ندارد'
                           WHEN '014' THEN N'⚠️ داده ای برای نمایش گزارش [ *افزایش 💳 شارژ خدمات شبکه های اجتماعی* ] وجود ندارد'
                      END + CHAR(10) + CHAR(10) +
                      CASE 
                        WHEN @FromDate = @todate THEN N'تاریخ گزارش [ *امروز* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 1 AND 7 THEN N'تاریخ گزارش [ *این هفته* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 8 AND 30 THEN N'تاریخ گزارش [ *این ماه* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 31 AND 365 THEN N'تاریخ گزارش [ *امسال* ]'
                        ELSE N'از تاریخ *' + dbo.GET_MTOS_U(@FromDate) + N'* تا تاریخ *' + dbo.GET_MTOS_U(@ToDate) + N'* *' + CAST(DATEDIFF(DAY, @FromDate, @ToDate) AS NVARCHAR(10)) + N'*'
                      END 
              FOR XML PATH('Message'), ROOT('Result')
            );
	   END -- IF @SubActnCode = '001'
	   -- گزارش کارمزد کسر شده
	   ELSE IF @SubActnCode = '002'
	   BEGIN
	      IF EXISTS(SELECT * FROM dbo.[Order] WHERE ORDR_TYPE = '004' AND ORDR_STAT = '004' AND TXID_DNRM IS NOT NULL AND CAST(STRT_DATE AS DATE) BETWEEN @FromDate AND @ToDate)
	      BEGIN
	         SET @xRet = (
	            SELECT CASE @CrdtType
	                        WHEN '013' THEN N'📊 گزارش کارمزد پرداخت ها' 
	                        WHEN '014' THEN N'📊 گزارش کارمزد خدمات شبکه های اجتماعی' 
	                   END + CHAR(10) + CHAR(10) +
	                   CASE 
                        WHEN @FromDate = @todate THEN N'تاریخ گزارش [ *امروز* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 1 AND 7 THEN N'تاریخ گزارش [ *این هفته* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 8 AND 30 THEN N'تاریخ گزارش [ *این ماه* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 31 AND 365 THEN N'تاریخ گزارش [ *امسال* ]'
                        ELSE N'از تاریخ *' + dbo.GET_MTOS_U(@FromDate) + N'* تا تاریخ *' + dbo.GET_MTOS_U(@ToDate) + N'* *' + CAST(DATEDIFF(DAY, @FromDate, @ToDate) AS NVARCHAR(10)) + N'*'
                      END + CHAR(10) + CHAR(10) +
	                   N'👈   [ جمع مبلغ کارمزد ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM(ISNULL(ISNULL(o.TXFE_AMNT_DNRM,0) + ISNULL(o.TXFE_CALC_AMNT_DNRM,0), 0))), 1), '.00', '') + N'*' + CHAR(10) +
	                   N'👈   [ تعداد دفعات کسر کارمزد ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(o.CODE)), 1), '.00', '') + N'* [ *بار* ]'+ CHAR(10) 
	              FROM dbo.[Order] o
	             WHERE o.ORDR_STAT = '004' -- درخواست پایانی شده باشد
	               AND o.ORDR_TYPE IN ('004')
	               AND CAST(o.STRT_DATE AS DATE) BETWEEN @FromDate AND @ToDate
	               AND o.TXID_DNRM IS NOT NULL
	           FOR XML PATH('Message'), ROOT('Result')	        
	         );
	      END 
	      ELSE
	         SET @xRet = (
               SELECT CASE @CrdtType
                           WHEN '013' THEN N'⚠️ داده ای برای نمایش گزارش [ *کارمزد پرداخت* ] وجود ندارد'
                           WHEN '014' THEN N'⚠️ داده ای برای نمایش گزارش [ *کارمزد خدمات شبکه های اجتماعی* ] وجود ندارد'
                      END + CHAR(10) + CHAR(10) +
                      CASE 
                        WHEN @FromDate = @todate THEN N'تاریخ گزارش [ *امروز* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 1 AND 7 THEN N'تاریخ گزارش [ *این هفته* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 8 AND 30 THEN N'تاریخ گزارش [ *این ماه* ]'
                        WHEN DATEDIFF(DAY, @FromDate, @ToDate) BETWEEN 31 AND 365 THEN N'تاریخ گزارش [ *امسال* ]'
                        ELSE N'از تاریخ *' + dbo.GET_MTOS_U(@FromDate) + N'* تا تاریخ *' + dbo.GET_MTOS_U(@ToDate) + N'* *' + CAST(DATEDIFF(DAY, @FromDate, @ToDate) AS NVARCHAR(10)) + N'*'
                      END 
              FOR XML PATH('Message'), ROOT('Result')
            );
	   END -- ELSE IF @SubActnCode = '002'
	END -- ELSE IF @MainActnCode = '002'
	
	
	COMMIT TRAN [T$MNGR_CRDT_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
      ROLLBACK TRAN [T$MNGR_CRDT_P];
	END CATCH
END
GO
