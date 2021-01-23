SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GET_ODST_U] ( @X XML )
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @RoboTokn VARCHAR(100)
           ,@RoboRbid BIGINT
           ,@Chatid BIGINT
           ,@OrdrNumb BIGINT
           ,@OwnrName NVARCHAR(250)
           ,@AllStat VARCHAR(3)
           ,@OrderStates NVARCHAR(MAX);
   
   SELECT @RoboTokn = @X.query('/Request').value('(Request/@robotokn)[1]','VARCHAR(100)')
         ,@Chatid = @X.query('/Request').value('(Request/@chatid)[1]','BIGINT')
         ,@OrdrNumb = @X.query('/Request').value('(Request/@ordrnumb)[1]','BIGINT')
         ,@OwnrName = @X.query('/Request').value('(Request/@ownrname)[1]','NVARCHAR(250)')
         ,@AllStat = @X.query('/Request').value('(Request/@allstat)[1]','VARCHAR(3)');
   
   -- بدست آوردن اطلاعات ربات
   SELECT @RoboRbid = RBID
     FROM dbo.Robot
    WHERE TKON_CODE = @RoboTokn;
   
   -- آیا کاربر فعلی به عنوان فروشنده درخواست فعلی برای او ثبت شده
   IF EXISTS(
      SELECT *
        FROM dbo.[Order] o
       WHERE o.PROB_ROBO_RBID = @RoboRbid
         AND (o.CHAT_ID = @Chatid/* OR MDFR_STAT = '002'*/ OR EXISTS(SELECT * FROM dbo.Order_Access oa WHERE oa.ORDR_CODE = o.CODE AND oa.CHAT_ID = @Chatid AND oa.RECD_STAT = '002'))
         AND o.ORDR_NUMB = @OrdrNumb
   )
   BEGIN      
      SELECT @OrderStates = (
         SELECT N'💡 در تاریخ ' + dbo.GET_CDTS_U(dbo.GET_MTOS_U(STAT_DATE)) + N' ' + CASE RIGHT(CONVERT(varchar(15),CAST(os.STAT_DATE AS TIME),100), 2) WHEN 'AM' THEN N'قبل از ظهر' ELSE N'بعد از ظهر' END  + N' سفارش در مرحله' + N' 👈 ' + a.TITL_DESC + N' قرار گرفت.' + N'( '+ ISNULL(os.STAT_DESC, N'بدون توضیحات') + N' )' + CHAR(10)
           FROM  dbo.[Order] o, dbo.Order_State os, dbo.App_Base_Define a
          WHERE o.CODE = os.ORDR_CODE
            AND o.ORDR_NUMB = @OrdrNumb
            AND (o.CHAT_ID = @Chatid/* OR MDFR_STAT = '002'*/ OR EXISTS(SELECT * FROM dbo.Order_Access oa WHERE oa.ORDR_CODE = o.CODE AND oa.CHAT_ID = @Chatid AND oa.RECD_STAT = '002'))
            AND o.PROB_ROBO_RBID = @RoboRbid            
            AND os.APBS_CODE = a.CODE
            AND (@AllStat = '002' OR os.CODE = (SELECT TOP 1 os1.CODE FROM dbo.Order_State os1 WHERE os.ORDR_CODE = os1.ORDR_CODE ORDER BY os1.STAT_DATE DESC))
          ORDER BY os.STAT_DATE DESC
            FOR XML PATH('')
      );
      
      SELECT @OrderStates = (
         SELECT N'👤 فروشنده گرامی ' + pr.NAME + CHAR(10) + N' 🏷 شماره سفارش ' + CAST(@OrdrNumb AS VARCHAR(10)) + CHAR(10) + N' 👪 برای مشتری ' + o.OWNR_NAME + N' 📞 با شماره ' + ISNULL(o.CELL_PHON, N'') + N' به شرح زیر می باشد: ' + CHAR(10) + @OrderStates
           FROM dbo.Personal_Robot pr, dbo.[Order] o
          WHERE pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
            AND pr.ROBO_RBID = o.PROB_ROBO_RBID
            AND pr.ROBO_RBID = @RoboRbid
            AND o.ORDR_NUMB = @OrdrNumb
            AND (o.CHAT_ID = @Chatid/* OR MDFR_STAT = '002'*/ OR EXISTS(SELECT * FROM dbo.Order_Access oa WHERE oa.ORDR_CODE = o.CODE AND oa.CHAT_ID = @Chatid AND oa.RECD_STAT = '002'))
      );
      RETURN @OrderStates;
   END
   ELSE IF EXISTS(
      SELECT *
        FROM dbo.[Order] o
       WHERE o.PROB_ROBO_RBID = @RoboRbid
         AND (o.CHAT_ID = @Chatid /*OR MDFR_STAT = '002'*/ OR EXISTS(SELECT * FROM dbo.Order_Access oa WHERE oa.ORDR_CODE = o.CODE AND oa.CHAT_ID = @Chatid AND oa.RECD_STAT = '002'))
         AND o.OWNR_NAME LIKE REPLACE(@OwnrName, N' ', N'%')
   )
   BEGIN
      SELECT @OrderStates = (
         SELECT N'👤 فروشنده ثبت کننده ' + pr.NAME + CHAR(10) + N' 🏷 شماره سفارش ' + CAST(o.ORDR_NUMB AS VARCHAR(10)) + CHAR(10) + N' 👪 برای مشتری ' + o.OWNR_NAME + N' 📞 با شماره ' + ISNULL(o.CELL_PHON, N'') + N' می باشد ' + CHAR(10) + N'+++++++++++++++++++++++++++' + CHAR(10)
           FROM dbo.Personal_Robot pr, dbo.[Order] o
          WHERE pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
            AND pr.ROBO_RBID = o.PROB_ROBO_RBID
            AND pr.ROBO_RBID = @RoboRbid
            AND o.OWNR_NAME LIKE REPLACE(@OwnrName, N' ', N'%')
            AND (o.CHAT_ID = @Chatid /*OR MDFR_STAT = '002'*/ OR EXISTS(SELECT * FROM dbo.Order_Access oa WHERE oa.ORDR_CODE = o.CODE AND oa.CHAT_ID = @Chatid AND oa.RECD_STAT = '002'))
          FOR XML PATH('')
      );
      RETURN @OrderStates;
   END
   
   RETURN N'⚠️ شماره سفارش وارد درست نمی باشد، لطفا با سرپرستی هماهنگ کنید';
END;
GO
