SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_RWRD_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY 
	   BEGIN TRAN T$SAVE_RWRD_P
   	
   	DECLARE @Rbid BIGINT,
   	        @RwrdType VARCHAR(3), -- نوع پاداش
   	        @WletType VARCHAR(3), -- نوع کیف مبلغ پاداش
   	        @TotlAmnt BIGINT, -- کل مبلغ
   	        @PrctAmnt INT, -- درصد محاسبه
   	        @Amnt BIGINT, -- مقدار پاداش
   	        @ConfDay INT, -- تعداد روز انتظار دریافت پاداش
   	        @TarfCode VARCHAR(100), -- کد تعرفه هزینه پاداش
   	        @ChatId BIGINT, -- صاحب پاداش
   	        @IntrChatId BIGINT, -- واسطه هزینه پاداش
   	        @OrdrDesc NVARCHAR(4000);
   	
   	SELECT @Rbid = @X.query('Reward').value('(Reward/@rbid)[1]', 'BIGINT'),
   	       @RwrdType = @X.query('Reward').value('(Reward/@type)[1]', 'VARCHAR(3)'),
   	       @WletType = @X.query('Reward').value('(Reward/@wlettype)[1]', 'VARCHAR(3)'),
   	       @TotlAmnt = @X.query('Reward').value('(Reward/@totlamnt)[1]', 'BIGINT'),
   	       @PrctAmnt = @X.query('Reward').value('(Reward/@prctamnt)[1]', 'INT'),
   	       @Amnt = @X.query('Reward').value('(Reward/@amnt)[1]', 'BIGINT'),
   	       @ConfDay = @X.query('Reward').value('(Reward/@confday)[1]', 'INT'),
   	       @TarfCode = @X.query('Reward').value('(Reward/@tarfcode)[1]', 'VARCHAR(100)'),
   	       @ChatId = @X.query('Reward').value('(Reward/@chatid)[1]', 'BIGINT'),
   	       @IntrChatId = @X.query('Reward').value('(Reward/@intrchatid)[1]', 'BIGINT'),
   	       @OrdrDesc = @X.query('Reward').value('(Reward/@desc)[1]', 'NVARCHAR(4000)');
   	
   	-- Local var
   	DECLARE @OrdrCode BIGINT = NULL,
   	        @WletCode BIGINT = NULL,
   	        @AmntType VARCHAR(3) = NULL,
   	        @AmntTypeDesc NVARCHAR(15) = NULL,
   	        @TDirPrjbCode BIGINT = NULL,
   	        @TOrdrCode BIGINT = NULL,
   	        @XMessage XML;
   	
   	SELECT @AmntType = r.AMNT_TYPE,
   	       @AmntTypeDesc = a.DOMN_DESC
   	  FROM dbo.Robot r, dbo.[D$AMUT] a
   	 WHERE r.RBID = @Rbid
   	   AND r.AMNT_TYPE = a.VALU;
   	
   	-- اضافه کردن مبلغ پاداش به صورت دستی به مشترکینی که علاقه دارید به آنها پاداش دهید
   	IF @RwrdType = '001'
   	BEGIN
   	   SELECT @OrdrCode = o.CODE
   	     FROM dbo.[Order] o
   	    WHERE o.ORDR_TYPE = '028'
   	      AND o.CHAT_ID = @ChatId
   	      AND o.ORDR_STAT = '001';
   	   
   	   SET @OrdrDesc += N' - ' + (
   	       SELECT N'به واسطه ' + sr.NAME + N' - ' + CAST(sr.CHAT_ID AS NVARCHAR(30))
   	         FROM dbo.Service_Robot sr
   	        WHERE sr.ROBO_RBID = @Rbid
   	          AND sr.CHAT_ID = @IntrChatId
   	   );
   	   
   	   IF @OrdrCode IS NULL
   	   BEGIN
   	      INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE, ORDR_DESC )
            SELECT dbo.GNRT_NVID_U(), sr.SERV_FILE_NO, sr.ROBO_RBID, '028', @OrdrDesc
              FROM dbo.Service_Robot sr
             WHERE sr.ROBO_RBID = @Rbid
               AND sr.CHAT_ID = @ChatId;
            
            SELECT @OrdrCode = o.CODE
   	        FROM dbo.[Order] o
   	       WHERE o.ORDR_TYPE = '028'
   	         AND o.CHAT_ID = @ChatId
   	         AND o.ORDR_STAT = '001';
   	   END    	   
   	   
   	   INSERT INTO dbo.Order_Detail(ORDR_CODE ,ELMN_TYPE ,TARF_CODE ,ORDR_CMNT ,ORDR_DESC, EXPN_PRIC, NUMB)
   	   VALUES(@OrdrCode, '001', @TarfCode, N'واریز مبلغ پاداش', @OrdrDesc, @Amnt, 1);
   	   
   	   -- درج ردیف وصولی در جدول وضعیت درخواست
	      INSERT INTO dbo.Order_State(ORDR_CODE ,CODE ,STAT_DATE ,AMNT ,AMNT_TYPE , RCPT_MTOD , CONF_STAT, CONF_DATE )
	      VALUES(@OrdrCode, 0, GETDATE(), @Amnt, '001', '001', '002', GETDATE());
   	   
   	   UPDATE o
	         SET o.Expn_Amnt = (SELECT SUM(od.EXPN_PRIC * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	            ,o.EXTR_PRCT = (SELECT SUM(od.EXTR_PRCT * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	            ,o.PYMT_AMNT_DNRM = (SELECT SUM(os.AMNT) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.code AND os.AMNT_TYPE IN ('001', '005') AND os.CONF_STAT = '002')
	            ,o.DSCN_AMNT_DNRM = (SELECT SUM(((od.EXPN_PRIC + od.EXTR_PRCT) * od.NUMB) * ISNULL(od.OFF_PRCT, 0) / 100 ) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE) + 
	                                (SELECT ISNULL(SUM(os.AMNT), 0) FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '002' /* تخفیفات سفارش */)
	            ,o.AMNT_TYPE = @AmntType
	        FROM dbo.[Order] o
	       WHERE o.CODE = @OrdrCode;	
   	   
   	   -- Found Wallet Code
   	   SELECT @WletCode = w.CODE
   	     FROM dbo.Wallet w
   	    WHERE w.SRBT_ROBO_RBID = @Rbid
   	      AND w.CHAT_ID = @ChatId
   	      AND w.WLET_TYPE = @WletType;
   	   
   	   INSERT INTO dbo.Wallet_Detail(ORDR_CODE ,WLET_CODE ,CODE , AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT, CONF_DATE, CONF_DESC)
         VALUES(@OrdrCode, @WletCode, dbo.GNRT_NVID_U(), @AmntType, @Amnt, GETDATE(), '001', '003', DATEADD(DAY, @ConfDay, GETDATE()), @OrdrDesc);
   	END 
   	
   	-- 1399/12/04 * پایانی کردن درخواست واریز وجه پاداش
   	UPDATE dbo.[Order] SET ORDR_STAT = '004' WHERE CODE = @OrdrCode;
   	
      -- ارسال پیام به مشتری جهت واریز وجه به حساب کیف پول
      INSERT INTO dbo.[Order] ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,CHAT_ID ,SUB_SYS ,ORDR_CODE ,CODE ,ORDR_TYPE ,ORDR_STAT )
      SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, sr.CHAT_ID, 5, @OrdrCode, dbo.GNRT_NVID_U(), '012', '001'
        FROM dbo.Service_Robot sr
       WHERE ROBO_RBID = @Rbid
         AND CHAT_ID = @ChatId;
      
      INSERT INTO dbo.Order_Detail ( ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT ,ORDR_DESC ,IMAG_PATH )
      SELECT o.CODE, '002', 
             CASE @WletType 
                  WHEN '001' THEN N'گزارش محاسبه پورسانت نقدی'
                  WHEN '002' THEN N'گزارش محاسبه پورسانت اعتباری'
             END , 
             N'*' + o.OWNR_NAME + N'* عزیز' + CHAR(10) + 
             N'😊🖐️ با سلام ضمن تشکر از زحمات شما ' + CHAR(10) + 
             N'📇 *محاسبه سود سهامداری فروشگاه های زنجیره ای شما*' + CHAR(10) + CHAR(10) +
             
             N'بابت 🛒 شارژ *' + sr.NAME + N'* به مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @TotlAmnt), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' در تاریخ *' + dbo.GET_MTOS_U(o.STRT_DATE) + N'* پاداش *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, /*((@TotlAmnt - ISNULL(@TxfeAmnt, 0)) * @TxfePrct / 100)*/@Amnt), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' برای شما لحاظ شده است.' + CHAR(10) + 
             CASE @ConfDay
                  WHEN 0 THEN N'که به حساب کیف پول شما واریز گردید' 
                  ELSE N'🔵 این مبلغ حداکثر تا *' + CAST(@ConfDay AS VARCHAR(2)) + N'* روز به حساب کیف پول شما واریز میگردد.'
             END + CHAR(10) + CHAR(10) +
             
             N'📍 _' + o.SORC_POST_ADRS + N'_' + CHAR(10) + 
             N'📲 _' + o.SORC_CELL_PHON + N'_' + CHAR(10) + 
             N'☎️ _' + o.SORC_TELL_PHON + N'_' + CHAR(10) + CHAR(10) + 
             N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)),
             (
               SELECT TOP 1 
                      og.FILE_ID
                 FROM dbo.Organ_Media og
                WHERE og.ROBO_RBID = @Rbid
                  AND og.STAT = '002'
                  AND og.RBCN_TYPE = '010'
                  AND og.IMAG_TYPE = '002'                
             )
        FROM dbo.[Order] o, dbo.Service_Robot sr
       WHERE o.ORDR_CODE = @OrdrCode
         AND o.ORDR_TYPE = '012'
         AND o.ORDR_STAT = '001'
         AND sr.ROBO_RBID = @Rbid
         AND sr.CHAT_ID = @IntrChatId;
      
      -- پیدا کردن کد مربوط به ارسال پیامک
      SELECT TOP 1 
             @TDirPrjbCode = a.CODE,
             @TOrdrCode = o.CODE
        FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
       WHERE a.PRBT_ROBO_RBID = @Rbid
         AND a.JOB_CODE = b.CODE
         AND b.ORDR_TYPE = '012' /* اعلام دریافت پورسانت */
         AND o.ORDR_TYPE = '012' /* اعلام دریافت پورسانت */
         AND o.ORDR_CODE = @OrdrCode
         AND o.CHAT_ID = @ChatId
         AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO;

      -- ارسال پیامک
      SELECT  @XMessage = ( 
         SELECT @TOrdrCode AS '@code' ,
                @Rbid AS '@roborbid' ,
                '012' '@type',
                @TDirPrjbCode '@dirprjbcode'
        FOR XML PATH('Order'), ROOT('Process')
      );
      EXEC Send_Order_To_Personal_Robot_Job @XMessage;        
   	
   	UPDATE dbo.[Order]
   	   SET ORDR_STAT = '004'
   	 WHERE ORDR_CODE = @OrdrCode
   	   AND ORDR_TYPE = '012'
   	   AND ORDR_STAT = '001';
   	
	   COMMIT TRAN [T$SAVE_RWRD_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR(@ErorMesg, 16, 1);
      ROLLBACK TRANSACTION [T$SAVE_RWRD_P];
	END CATCH
END
GO
