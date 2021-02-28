SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mohsen Hadaeghi
-- Create date: 1399/01/24
-- Description:	ارسال پیام های وابسته بعد از ایجاد درخواست اولیه
-- Send Message Event New Order To Personel Job Order Depended
-- هدف از ساخت این رویه این هست که بعد از اینکه یه درخواستی درون سیستم ثبت شد که اگر نیاز باشد افرادی از  این درخواست با اطلاع باشند و بخواهند سرویس های بعدی 
-- را ارائه کنند و درخواست سریع تر جلو برود ساخته شده
-- =============================================
CREATE PROCEDURE [dbo].[SEND_MEOJ_P]
	@X XML,
	@XRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$SEND_MEOJ_P];
	/*
	   <Robot rbid="">
	      <Order chatid="" code="" type="" value="" oprt=""/>
	   </Robot>
	*/
	-- Init var
	DECLARE @Rbid BIGINT = @x.query('//Robot').value('(Robot/@rbid)[1]', 'BIGINT')
	       ,@UssdCode VARCHAR(100) = @x.query('//Order').value('(Order/@ussdcode)[1]', 'VARCHAR(250)')
	       ,@Chatid BIGINT = @x.query('//Order').value('(Order/@chatid)[1]', 'BIGINT')
	       ,@OrdrCode BIGINT = @x.query('//Order').value('(Order/@code)[1]', 'BIGINT')
	       ,@OrdrType VARCHAR(3) = @x.query('//Order').value('(Order/@type)[1]', 'VARCHAR(3)');
	
	-- local var 
	DECLARE @XMessage XML,
	        @TOrdrCode BIGINT,
	        @TOrdrType VARCHAR(3),
	        @RsltCode VARCHAR(3),
	        @TAutoShipCori VARCHAR(3),
	        @TFileId VARCHAR(500),
	        @TDirPrjbCode BIGINT,
	        @Oprt VARCHAR(50),
	        @Valu NVARCHAR(MAX),
	        @TarfCode VARCHAR(100),
	        @TChatId BIGINT,
	        @AdminChatId BIGINT;
	
	IF @OrdrType = '004' -- ثبت سفارش	
	BEGIN
	   -- بدست آوردن عکس مربوط به ثبت سفارش
	   SELECT @TFileId = FILE_ID
	     FROM dbo.Organ_Media
	    WHERE ROBO_RBID = @Rbid
	      AND RBCN_TYPE = '007'
	      AND IMAG_TYPE = '002'
	      AND STAT = '002';
	   
	   BEGIN/* اطلاعات مربوط به پیام های از واحد های مختلف به مشتری */
	      -- آماده سازی ارسال پیام به مشتری از شغل های مختلف
	      INSERT  INTO dbo.[Order](CODE, ORDR_CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
	      SELECT dbo.GNRT_NVID_U(), o.CODE, o.SRBT_SERV_FILE_NO, o.SRBT_ROBO_RBID, '012', GETDATE(), '001'
	        FROM dbo.[Order] o
	       WHERE o.CODE = @OrdrCode;
	      
	      --INSERT INTO dbo.Order_Detail
       --  (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
       --  SELECT o.CODE, '002', N'سامانه اطلاع رسانی وضعیت سفارش بابت فروش آنلاین', @TFileId,
       --        (
       --           SELECT N'📝 [ اطلاعات فاکتور ]' + CHAR(10) +
       --                  N'[ وضعیت فاکتور ] : *' +  N'✅ پرداخت شده *' + CHAR(10) + 
	      --                N'[ شماره فاکتور ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'* [ کد سیستم ] : *' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + N'*' + CHAR(10) + 
	      --                N'[ مبلغ فاکتور ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ]* ' + CHAR(10) + 
	      --                --N'🗓 [ ایجاد فاکتور ] : *' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) +
	      --                N'[ پرداخت فاکتور ] : *' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) + 
	      --                N'👤 [ اطلاعات مشترک ] ' + CHAR(10) +
	      --                N'[ کداشتراک ] : ' + CAST(s.CHAT_ID AS VARCHAR(20)) + CHAR(10) +
	      --                N'[ نام کاربری ] : ' + s.FRST_NAME + N', ' + s.LAST_NAME + CHAR(10) + 
	      --                N'[ شماره موبایل ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) 
	      --           FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s, dbo.[D$AMUT] au
	      --          WHERE o.CODE = @OrdrCode
	      --            AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	      --            AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	      --            AND sr.SERV_FILE_NO = s.FILE_NO
	      --            AND o.AMNT_TYPE = au.VALU
       --        )
       --    FROM dbo.[Order] o
       --   WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
       --     AND o.ORDR_STAT = '001'
       --     AND o.ORDR_CODE = @OrdrCode;
	   END 
	   BEGIN/* اطلاعات مربوط به شغل حسابداری */
	      -- آماده سازی ارسال پیام به شغل حسابداری
         INSERT  INTO dbo.[Order](CODE, ORDR_CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), @OrdrCode, pr.SERV_FILE_NO, pr.ROBO_RBID, '017', GETDATE(), '001'
           FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj 
          WHERE j.CODE = prj.JOB_CODE 
            AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
            AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
            AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
            AND j.ROBO_RBID = @Rbid
            AND j.ORDR_TYPE = '017'
            AND pr.STAT = '002'
            AND prj.STAT = '002';
         
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT o.CODE, '002', N'ثبت سند وصولی بابت فروش آنلاین', @TFileId,
               (
                  SELECT N'📝 [ اطلاعات فاکتور ]' + CHAR(10) +
                         N'[ وضعیت فاکتور ] : *' +  N'✅ پرداخت شده *' + CHAR(10) + 
	                      N'[ شماره فاکتور ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'* [ کد سیستم ] : *' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + N'*' + CHAR(10) + 
	                      N'[ مبلغ فاکتور ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ]* ' + CHAR(10) + 
	                      --N'🗓 [ ایجاد فاکتور ] : *' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) +
	                      N'[ پرداخت فاکتور ] : *' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) + 
	                      N'👤 [ اطلاعات مشترک ] ' + CHAR(10) +
	                      N'[ کداشتراک ] : ' + CAST(s.CHAT_ID AS VARCHAR(20)) + CHAR(10) +
	                      N'[ نام کاربری ] : ' + sr.REAL_FRST_NAME + N', ' + sr.REAL_LAST_NAME + CHAR(10) + 
	                      N'[ شماره موبایل ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) + 
	                      N'[ شماره پیگیری ] : *' + ISNULL(o.TXID_DNRM, N'---') + N'*' + CHAR(10) + CHAR(10) +
	                      N'💳 [ کارت مقصد ] ' + CHAR(10) + 
	                      (SELECT DISTINCT N'*' + a.CARD_NUMB_DNRM + CHAR(10) + a.BANK_NAME + N' - ' + a.ACNT_OWNR + N'*' FROM dbo.Robot_Card_Bank_Account a WHERE a.ROBO_RBID = @Rbid AND a.CARD_NUMB = o.DEST_CARD_NUMB_DNRM)
	                 FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s, dbo.[D$AMUT] au
	                WHERE o.CODE = @OrdrCode
	                  AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	                  AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	                  AND sr.SERV_FILE_NO = s.FILE_NO
	                  AND o.AMNT_TYPE = au.VALU
               )
           FROM dbo.[Order] o
          WHERE o.ORDR_TYPE = '017' -- درخواست های حسابداری
            AND o.ORDR_STAT = '001'
            AND o.ORDR_CODE = @OrdrCode;   	   
	      -- پایان پیام شغل حسابداری
	   END 	   
	   BEGIN/* اطلاعات مربوط به شغل انبارداری */
	      -- ارسال پیام به واحد انبار
	      INSERT  INTO dbo.[Order](CODE, ORDR_CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), @OrdrCode, pr.SERV_FILE_NO, pr.ROBO_RBID, '018', GETDATE(), '001'
           FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj 
          WHERE j.CODE = prj.JOB_CODE 
            AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
            AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
            AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
            AND j.ROBO_RBID = @Rbid
            AND j.ORDR_TYPE = '018'
            AND pr.STAT = '002'
            AND prj.STAT = '002';
         
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT o.CODE, '002', N'ثبت حواله بابت فروش آنلاین', @TFileId,
               (
                  SELECT N'📝 [ اطلاعات حواله ]' + CHAR(10) +
                         N'[ وضعیت حواله ] : *' +  N'✅ تایید شده *' + CHAR(10) + 
	                      N'[ شماره حواله ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'* [ کد سیستم ] : *' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + N'*' + CHAR(10) + 
	                      N'[ تاریخ و زمان ] : *' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) + 
                         
                         N'👤 [ اطلاعات مشترک ] ' + CHAR(10) +
	                      N'[ کداشتراک ] : ' + CAST(s.CHAT_ID AS VARCHAR(20)) + CHAR(10) +
	                      N'[ نام کاربری ] : ' + sr.REAL_FRST_NAME + N', ' + sr.REAL_LAST_NAME + CHAR(10) + 
	                      N'[ شماره موبایل ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) + CHAR(10) +
	                         	                   
	                      N'[ اقلام فاکتور ] : ' + CHAR(10) + 
	                      (
	                         SELECT N'*' + CAST(ROW_NUMBER() OVER (ORDER BY od.RWNO) AS NVARCHAR(4)) + N' ) ' + 
	                                /*N'📦 '+*/ rp.TARF_TEXT_DNRM + CHAR(10) + 	                           
	                                N'🔢 تعداد : ' + CAST(od.NUMB AS NVARCHAR(10)) + N'  [ ' + a.TITL_DESC + N' ]*'+ CHAR(10) + CHAR(10) 
	                           FROM dbo.Order_Detail od, dbo.Robot_Product rp, dbo.App_Base_Define a
	                          WHERE od.ORDR_CODE = o.CODE
  	                            AND od.TARF_CODE = rp.TARF_CODE
	                            AND rp.UNIT_APBS_CODE = a.CODE
	                            AND rp.ROBO_RBID = @Rbid
	                            FOR XML PATH('')
	                      )
	                 FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s, dbo.[D$AMUT] au
	                WHERE o.CODE = @OrdrCode
	                  AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	                  AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	                  AND sr.SERV_FILE_NO = s.FILE_NO
	                  AND o.AMNT_TYPE = au.VALU
               )
           FROM dbo.[Order] o
          WHERE o.ORDR_TYPE = '018' -- درخواست های انبارداری
            AND o.ORDR_STAT = '001'
            AND o.ORDR_CODE = @OrdrCode;
	       -- پایان پیام شغل انبارداری
	   END
      
      -- اطلاع رسانی به تامین کنندگان کالا یا محصول
      BEGIN 
         -- بدست آوردن عکس مربوط به ثبت سفارش
	      SELECT @TFileId = FILE_ID
	        FROM dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND RBCN_TYPE = '027'
	         AND IMAG_TYPE = '002'
	         AND STAT = '002';
	      
         DECLARE C$OthrSlerProd CURSOR FOR
            SELECT DISTINCT sp.CHAT_ID
              FROM dbo.Service_Robot_Seller_Product sp, dbo.Order_Detail od
             WHERE od.ORDR_CODE = @OrdrCode
               AND od.TARF_CODE = sp.TARF_CODE
               AND NOT EXISTS (
                       SELECT *
                         FROM dbo.Service_Robot sr, dbo.Service_Robot_Group g
                        WHERE sr.SERV_FILE_NO = g.SRBT_SERV_FILE_NO
                          AND sr.ROBO_RBID = g.SRBT_ROBO_RBID
                          AND sr.ROBO_RBID = @Rbid                       
                          AND g.GROP_GPID = 131 -- گروه مدیران
                          AND sp.CHAT_ID = sr.CHAT_ID
                          AND g.STAT = '002'
                   );
         
         OPEN [C$OthrSlerProd];
         L$Loop_C$OthrSlerProd:
         FETCH [C$OthrSlerProd] INTO @TChatId;
         
         IF @@FETCH_STATUS <> 0
            GOTO L$EndLoop_C$OthrSlerProd;
         
         SET @TOrdrCode = dbo.GNRT_NVID_U();
         INSERT INTO dbo.[Order] (SRBT_SERV_FILE_NO, SRBT_ROBO_RBID, ORDR_CODE, CODE, ORDR_TYPE, ORDR_DESC)
         SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, @OrdrCode, dbo.GNRT_NVID_U(), '012', @TOrdrCode
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @TChatId;
         
         SELECT @TOrdrCode = o.CODE , @TOrdrType = o.ORDR_TYPE  
           FROM dbo.[Order] o
          WHERE o.SRBT_ROBO_RBID = @Rbid
            AND o.ORDR_CODE = @OrdrCode
            AND o.CHAT_ID = @TChatId
            AND o.ORDR_TYPE = '012'
            AND o.ORDR_STAT = '001'
            AND o.ORDR_DESC = @TOrdrCode;
         
         INSERT INTO dbo.Order_Detail (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT @TOrdrCode, '002', N'تبریک! بابت فروش محصول', @TFileId, 
                N'😊 *تامین کننده عزیز*' + CHAR(10) + CHAR(10) + 
                N'مشتری *' + o.OWNR_NAME + N'* به شماره درخواست *' + CAST(o.CODE AS NVARCHAR(15)) + N'* - ' + N' به شماره فاکتور *' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(15)) + N'* درخواست اقلام زیر را داشته، لطفا موارد زیر را آماده کنید که فروشگاه از شما تحویل بگیرد' + CHAR(10) + CHAR(10) + 
                (
                  SELECT N'📦 *' + CAST(od.NUMB AS NVARCHAR(10)) + N' ' + rp.UNIT_DESC_DNRM + N' ( ' + rp.TARF_CODE + N' )' + N' [ ' + rp.TARF_TEXT_DNRM +  + N' ] *'+ CHAR(10)
                    FROM dbo.Order_Detail od, dbo.Service_Robot_Seller_Product sp, dbo.Robot_Product rp
                   WHERE od.ORDR_CODE = o.CODE
                     AND od.TARF_CODE = sp.TARF_CODE
                     AND sp.CHAT_ID = @TChatId
                     AND rp.TARF_CODE = od.TARF_CODE
                     AND rp.ROBO_RBID = @Rbid
                     FOR XML PATH('')
                ) + CHAR(10) + CHAR(10) +
                N'باتشکر از شما تامین کننده گرامی' + CHAR(10) + 
                N'*واحد انبار فروشگاه*'
           FROM dbo.[Order] o
          WHERE o.CODE = @OrdrCode;
         
         -- 1399/09/15 * اضافه شدن مبلغ کیف پول نقدینگی به حساب تامین کننده جهت دریافت پول فروش کالا
         INSERT INTO dbo.Wallet_Detail ( ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC )
         SELECT @OrdrCode, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, od.BUY_PRIC_DNRM * od.NUMB, GETDATE(), '001', '002', GETDATE(), N'واریز وجه فروش محصول فروخته شده ( ' + rp.TARF_CODE + N' ) [ ' + rp.TARF_TEXT_DNRM + N' ] از فروشگاه انلاین'
           FROM dbo.Wallet w, dbo.[Order] o, dbo.Order_Detail od, dbo.Service_Robot_Seller_Product sp, dbo.Robot_Product rp
          WHERE o.CODE = @OrdrCode
            AND od.ORDR_CODE = o.CODE
            AND od.TARF_CODE = sp.TARF_CODE
            AND sp.CHAT_ID = @TChatId
            AND rp.TARF_CODE = od.TARF_CODE
            AND rp.ROBO_RBID = @Rbid
            AND w.SRBT_ROBO_RBID = rp.ROBO_RBID
            AND w.CHAT_ID = @TChatId
            AND w.WLET_TYPE = '002'
            AND (od.BUY_PRIC_DNRM * od.NUMB) > 0;
         
         SET @TDirPrjbCode = NULL;
         -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود         
         SELECT @TDirPrjbCode = a.CODE
           FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
          WHERE a.PRBT_ROBO_RBID = @Rbid
            AND a.JOB_CODE = b.CODE
            AND b.ORDR_TYPE = @TOrdrType
            AND o.CODE = @TOrdrCode
            AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
         
         SELECT  @XMessage = ( 
            SELECT @TOrdrCode AS '@code' ,
                   @Rbid AS '@roborbid' ,
                   @TOrdrType '@type',
                   @TDirPrjbCode '@dirprjbcode'
           FOR XML PATH('Order'), ROOT('Process')
         );
         EXEC Send_Order_To_Personal_Robot_Job @XMessage;
         
         UPDATE dbo.[Order]
            SET ORDR_STAT = '004',
                ORDR_DESC += N' - ' + N'درخواست اطلاع رسانی به تامین کننده های محترم'
          WHERE CODE = @TOrdrCode;
         
         GOTO L$Loop_C$OthrSlerProd;
         L$EndLoop_C$OthrSlerProd:
         CLOSE [C$OthrSlerProd];
         DEALLOCATE [C$OthrSlerProd];
      END 
      
      -- اگر درخواست نیاز به پیک موتوری یا باربری داشته باشد
	   IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND o.HOW_SHIP != '001' /* ارسال بسته به سمت مشتری میباشد */)
	   BEGIN
	      -- برای ارسال پیام به سفیران
	      SELECT @TAutoShipCori = AUTO_SHIP_CORI
	        FROM dbo.Robot
	       WHERE RBID = @Rbid;
   	   
	      IF @TAutoShipCori = '002'
	      BEGIN/* اطلاعات مربوط به شغل پیک موتوری */
	         -- ارسال پیام به واحد سفیران
	         INSERT  INTO dbo.[Order](CODE, ORDR_CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
            SELECT dbo.GNRT_NVID_U(), @OrdrCode, pr.SERV_FILE_NO, pr.ROBO_RBID, '019', GETDATE(), '001'
              FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj, dbo.Wallet w
             WHERE j.CODE = prj.JOB_CODE 
               AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
               AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
               AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
               AND pr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
               AND pr.ROBO_RBID = w.SRBT_ROBO_RBID
               AND pr.CHAT_ID = w.CHAT_ID
               AND j.ROBO_RBID = @Rbid
               AND j.ORDR_TYPE = '019'
               AND pr.STAT = '002'
               AND prj.STAT = '002'
               AND w.WLET_TYPE = '001' -- Credit Wallet
               AND w.AMNT_DNRM > 0;            
            -- ثبت پیام همراه با عکس برای ارسال به مخاطبین
            INSERT INTO dbo.Order_Detail
            (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
            SELECT o.CODE, '002', N'ثبت ارسال بسته بابت فروش آنلاین', @TFileId,
                  (
                     SELECT N'📝 [ اطلاعات ارسال بسته ]' + CHAR(10) +
                            N'[ وضعیت ارسال بسته ] : *' +  N'✅ تایید شده *' + CHAR(10) + 
	                         N'[ شماره فاکتور ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'* [ کد سیستم ] : *' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + N'*' + CHAR(10) + 
	                         N'[ تاریخ و زمان ] : *' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) + 

                            N'👤 [ اطلاعات مشترک ] ' + CHAR(10) +
	                         N'[ کداشتراک ] : ' + CAST(s.CHAT_ID AS VARCHAR(20)) + CHAR(10) +
	                         N'[ نام کاربری ] : ' + sr.REAL_FRST_NAME + N', ' + sr.REAL_LAST_NAME + CHAR(10) + 
	                         N'[ شماره موبایل ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) +
      	                   N'[ آدرس مقصد ] : *' + ISNULL(sr.SERV_ADRS, N'---') + N'*' + CHAR(10) + 
      	                   N'موقعیت مکانی : * X : ' + CAST(ISNULL(o.CORD_X, 0) AS NVARCHAR(30)) + N' Y : ' + CAST(ISNULL(o.CORD_Y, 0) AS NVARCHAR(30)) + N'*' + CHAR(10) +
                            CASE WHEN ISNULL(o.CORD_X, 0) != 0 AND ISNULL(o.CORD_Y, 0) != 0 THEN dbo.STR_FRMT_U(N'📍 [موقعیت مکانی](https://www.google.com/maps?q=loc:{0},{1})', CAST(o.CORD_X AS VARCHAR(30)) + ',' + CAST(o.CORD_Y AS VARCHAR(30))) + CHAR(10) ELSE N'' END + CHAR(10) + 
      	                   
	                         N'[ اقلام بسته ] : ' + CHAR(10) + 
	                         (
	                            SELECT N'*' + CAST(ROW_NUMBER() OVER (ORDER BY od.RWNO) AS NVARCHAR(4)) + N' ) ' + 
	                                   /*N'📦 '+*/ rp.TARF_TEXT_DNRM + CHAR(10) + 	                           
	                                   N'🔢 تعداد : ' + CAST(od.NUMB AS NVARCHAR(10)) + N'  [ ' + a.TITL_DESC + N' ] ' + CASE ISNULL(rp.WEGH_AMNT_DNRM, 0) WHEN 0 THEN N'' ELSE N'⚖️ وزن : ' + CAST((rp.WEGH_AMNT_DNRM / 1000) * od.NUMB AS NVARCHAR(10)) + N'  [ کیلوگرم ]*' END + CHAR(10) + CHAR(10) 
	                              FROM dbo.Order_Detail od, dbo.Robot_Product rp, dbo.App_Base_Define a
	                             WHERE od.ORDR_CODE = o.CODE
  	                               AND od.TARF_CODE = rp.TARF_CODE
	                               AND rp.UNIT_APBS_CODE = a.CODE
	                               AND rp.ROBO_RBID = @Rbid
	                               FOR XML PATH('')
	                         )
	                    FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s, dbo.[D$AMUT] au
	                   WHERE o.CODE = @OrdrCode
	                     AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	                     AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	                     AND sr.SERV_FILE_NO = s.FILE_NO
	                     AND o.AMNT_TYPE = au.VALU
                  )
              FROM dbo.[Order] o
             WHERE o.ORDR_TYPE = '019' -- درخواست های سفیران
               AND o.ORDR_STAT = '001'
               AND o.ORDR_CODE = @OrdrCode;
	         -- پایان پیام شغل سفیران
	         
	         /* آن دسته از سفیرانی که برای خود اعتبار ثبت نکرده اند و بسته ها به دست آنها نمیرسد پس پیام عدم دریافت سفارش را برایشان ارسال میکنیم */
	         -- ارسال پیام به واحد سفیران بدون اعتبار
	         INSERT  INTO dbo.[Order](CODE, ORDR_CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
            SELECT dbo.GNRT_NVID_U(), @OrdrCode, pr.SERV_FILE_NO, pr.ROBO_RBID, '019', GETDATE(), '005'
              FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj, dbo.Wallet w
             WHERE j.CODE = prj.JOB_CODE 
               AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
               AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
               AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
               AND pr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
               AND pr.ROBO_RBID = w.SRBT_ROBO_RBID
               AND pr.CHAT_ID = w.CHAT_ID
               AND j.ROBO_RBID = @Rbid
               AND j.ORDR_TYPE = '019'
               AND pr.STAT = '002'
               AND prj.STAT = '002'
               AND w.WLET_TYPE = '001' -- Credit Wallet
               AND w.AMNT_DNRM <= 0;
               
            -- ثبت پیام همراه با عکس برای ارسال به مخاطبین
            INSERT INTO dbo.Order_Detail
            (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
            SELECT o.CODE, '002', N'عدم دریافت سفارش بسته بابت فروش آنلاین', @TFileId, 
                   N'سفیر عزیز با سلام' + CHAR(10) + 
                   N'به دلیل عدم اعتبار کافی برای دریافت سفارشات لطفا یکی از موارد زیر را انتخاب کنید' + CHAR(10) + 
                   N'🔵 شارژ اعتبار' + CHAR(10) + 
                   CHAR(9) + N'◀️ شما با افزایش اعتبار خود میتوانید متقاضی دریافت بسته های سفارش فروشگاه شوید، جهت افزایش اعتبار دکمه *💎 کیف پول* خود را فشار دهید' + CHAR(10) +
                   N'🔴 قطع همکاری' + CHAR(10) + 
                   CHAR(9) + N'◀️ در صورت عدم همکاری و قطع ارتباط جهت ماندن در سمت سفیر لطفا دکمه *🙏😔 عدم همکاری و قطع ارتباط* را فشار دهید'
              FROM dbo.[Order] o
             WHERE o.ORDR_TYPE = '019' -- درخواست های سفیران
               AND o.ORDR_STAT = '005' -- بایگانی شده ها
               AND o.ORDR_CODE = @OrdrCode;
	         -- پایان پیام شغل سفیران بدون اعتبار
	      END   
	   END
	   
	   BEGIN/* آماده سازی ارسال پیام به مخاطبین */
	      DECLARE C$SndMsg2PJob CURSOR FOR
	         SELECT o.CODE, o.ORDR_TYPE
	           FROM dbo.[Order] o
	          WHERE o.ORDR_CODE = @OrdrCode
	            AND o.ORDR_STAT IN ( '001', '005' )
	            AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */,'017' /* شغل حسابداری */, '018' /* شغل انبارداری */, '019' /* شغل سفیران */)
   	   
	      OPEN [C$SndMsg2PJob];
	      L$Loop_C$SndMsg2PJob:
	      FETCH [C$SndMsg2PJob] INTO @TOrdrCode, @TOrdrType;
   	   
	      IF @@FETCH_STATUS <> 0
	         GOTO L$EndLoop_C$SndMsg2PJob;
   	      
         UPDATE dbo.[Order]
            SET ORDR_STAT = CASE ORDR_STAT WHEN '001' THEN '002' ELSE ORDR_STAT END
          WHERE CODE = @TOrdrCode;
         
         SET @XMessage = (
            SELECT @Rbid AS '@rbid'
                  ,@ChatID AS '@chatid'
                  ,opi.CMND_TEXT  AS '@cmndtext'
                  ,os.CODE AS '@ordrcode'
              FROM dbo.[Order] ot, dbo.[Order] os, dbo.Order_Process_InLineKeyboard opi
             WHERE ot.CODE = @OrdrCode
               AND os.CODE = @TOrdrCode
               AND opi.ROBO_RBID = @Rbid
               AND opi.TRGT_ORDR_TYPE = ot.ORDR_TYPE
               AND opi.TRGT_ORDR_STAT = ot.ORDR_STAT
               AND opi.SLAV_ORDR_TYPE = os.ORDR_TYPE
               AND opi.SLAV_ORDR_STAT = os.ORDR_STAT
               FOR XML PATH('RequestInLineQuery')
         )
         EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
         SET @XMessage = (
             SELECT 1 AS '@order',
                    @XMessage
                FOR XML PATH('InlineKeyboardMarkup')
         );         
         
         -- ثبت منوی برای خروجی نهایی
         UPDATE dbo.Order_Detail
            SET INLN_KEYB_DNRM = @XMessage
          WHERE ORDR_CODE = @TOrdrCode;         
         
         SET @TDirPrjbCode = NULL;
         -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
         IF @TOrdrType IN ( '012', '017', '018', '019' )
         BEGIN
            SELECT @TDirPrjbCode = a.CODE
              FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
             WHERE a.PRBT_ROBO_RBID = @Rbid
               AND a.JOB_CODE = b.CODE
               AND b.ORDR_TYPE = @TOrdrType
               AND o.CODE = @TOrdrCode
               AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
         END 
         
         SELECT  @XMessage = ( 
            SELECT @TOrdrCode AS '@code' ,
                   @Rbid AS '@roborbid' ,
                   @TOrdrType '@type',
                   @TDirPrjbCode '@dirprjbcode'
           FOR XML PATH('Order'), ROOT('Process')
         );
         EXEC Send_Order_To_Personal_Robot_Job @XMessage;
         
         GOTO L$Loop_C$SndMsg2PJob;
         L$EndLoop_C$SndMsg2PJob:
         CLOSE [C$SndMsg2PJob];
         DEALLOCATE [C$SndMsg2PJob];
	   END
	END 
	ELSE IF @OrdrType = '024' -- ثبت درخواست واریز وجه برای مشتری
	BEGIN
	   IF NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.ORDR_CODE = @OrdrCode AND o.ORDR_TYPE IN ('012' ,'017'))
	   BEGIN
	      -- بدست آوردن عکس مربوط به ثبت سفارش
	      SELECT @TFileId = FILE_ID
	        FROM dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND RBCN_TYPE = '015'
	         AND IMAG_TYPE = '002'
	         AND STAT = '002';
   	   
	      BEGIN/* اطلاعات مربوط به پیام های از واحد حسابداری */
	         -- گام اول در این مرحله باید پیامی به حسابدار فروشگاه ارسال کنیم
            -- آماده سازی ارسال پیام به شغل حسابداری
            INSERT  INTO dbo.[Order](CODE, ORDR_CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, DEST_CARD_NUMB_DNRM)
            SELECT dbo.GNRT_NVID_U(), @OrdrCode, pr.SERV_FILE_NO, pr.ROBO_RBID, '017', GETDATE(), '001', o.SORC_CARD_NUMB_DNRM
              FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj, dbo.[Order] o 
             WHERE j.CODE = prj.JOB_CODE 
               AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
               AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
               AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
               AND j.ROBO_RBID = @Rbid
               AND o.CODE = @OrdrCode
               AND j.ORDR_TYPE = '017'
               AND pr.STAT = '002'
               AND prj.STAT = '002';
            
            INSERT INTO dbo.Order_Detail
            (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
            SELECT o.CODE, '002', N'سامانه اطلاع رسانی وضعیت درخواست واریز وجه', @TFileId,
                  (
                     SELECT N'📝 *اطلاعات درخواست وجه مشتری* ' + CHAR(10) +
                            N'[ وضعیت درخواست ] : *' +  N'✅ ثبت شده *' + CHAR(10) + 
                            N'[ شماره درخواست ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'* [ کد سیستم ] : *' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + N' - ' + o.ORDR_TYPE + N'*' + CHAR(10) + 
                            N'[ مبلغ درخواست ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ]* ' + CHAR(10) + 
                            N'[ مبلغ کسر کارمزد ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_FEE_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ]* ' + CHAR(10) + 
                            N'[ تاریخ ایجاد درخواست ] : *' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) +
                            --N'[ پرداخت فاکتور ] : *' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) + 
                            N'👤 *اطلاعات مشترک* ' + CHAR(10) +
                            N'[ کداشتراک ] : *' + CAST(s.CHAT_ID AS VARCHAR(20)) + N'*' + CHAR(10) +
                            N'[ نام کاربری ] : *' + s.FRST_NAME + N', ' + s.LAST_NAME + N'*' + CHAR(10) + 
                            N'[ شماره موبایل ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) + 
                            --N'[ شماره پیگیری ] : *' + o.TXID_DNRM + N'*' + CHAR(10) + CHAR(10) +
                            N'[ کارت مقصد ] 💳' + CHAR(10) +
                            (SELECT DISTINCT N'*' + a.CARD_NUMB_DNRM +  CHAR(10) + N'شماره شبا : ' + ISNULL(a.SHBA_NUMB, N'---') + CHAR(10) + a.BANK_NAME + N' - ' + a.ACNT_OWNR + N'*' FROM dbo.Robot_Card_Bank_Account a WHERE a.ROBO_RBID = @Rbid AND a.CARD_NUMB = o.SORC_CARD_NUMB_DNRM)
                       FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s, dbo.[D$AMUT] au
                      WHERE o.CODE = @OrdrCode
                        AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                        AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                        AND sr.SERV_FILE_NO = s.FILE_NO
                        AND o.AMNT_TYPE = au.VALU
                  )
              FROM dbo.[Order] o
             WHERE o.ORDR_TYPE = '017' -- درخواست های حسابداری
               AND o.ORDR_STAT = '001'
               AND o.ORDR_CODE = @OrdrCode;   	   
            -- پایان پیام شغل حسابداری
         END 
         BEGIN/* اطلاعات مربوط به پیام های از واحد های مختلف به مشتری */
	         -- آماده سازی ارسال پیام به مشتری از شغل های مختلف
	         INSERT  INTO dbo.[Order](CODE, ORDR_CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
	         SELECT dbo.GNRT_NVID_U(), o.CODE, o.SRBT_SERV_FILE_NO, o.SRBT_ROBO_RBID, '012', GETDATE(), '001'
	           FROM dbo.[Order] o
	          WHERE o.CODE = @OrdrCode;
   	      
	         INSERT INTO dbo.Order_Detail
            (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
            SELECT o.CODE, '002', N'سامانه اطلاع رسانی وضعیت درخواست واریز وجه', @TFileId,
              (
                  SELECT N'📝 *اطلاعات درخواست وجه مشتری* ' + CHAR(10) +
                         N'[ وضعیت درخواست ] : *' +  N'✅ ثبت شده *' + CHAR(10) + 
                         N'[ شماره درخواست ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'* [ کد سیستم ] : *' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + N' - ' + o.ORDR_TYPE + N'*' + CHAR(10) + 
                         N'[ مبلغ درخواست ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ]* ' + CHAR(10) + 
                         N'[ مبلغ کسر کارمزد ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_FEE_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ]* ' + CHAR(10) + 
                         N'[ تاریخ ایجاد درخواست ] : *' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) + 
                         --N'[ پرداخت فاکتور ] : *' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) + 
                         N'👤 *اطلاعات مشترک* ' + CHAR(10) +
                         N'[ کداشتراک ] : *' + CAST(s.CHAT_ID AS VARCHAR(20)) + N'*' + CHAR(10) +
                         N'[ نام کاربری ] : *' + s.FRST_NAME + N', ' + s.LAST_NAME + N'*' + CHAR(10) + 
                         N'[ شماره موبایل ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) + 
                         --N'[ شماره پیگیری ] : *' + o.TXID_DNRM + N'*' + CHAR(10) + CHAR(10) +
                         N'[ کارت مقصد ] 💳' + CHAR(10) +
                         (SELECT DISTINCT N'*' + a.CARD_NUMB_DNRM + CHAR(10) + N'شماره شبا : ' + ISNULL(a.SHBA_NUMB, N'---') + CHAR(10) + a.BANK_NAME + N' - ' + a.ACNT_OWNR + N'*' FROM dbo.Robot_Card_Bank_Account a WHERE a.ROBO_RBID = @Rbid AND a.CARD_NUMB = o.SORC_CARD_NUMB_DNRM)
                    FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s, dbo.[D$AMUT] au
                   WHERE o.CODE = @OrdrCode
                     AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                     AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                     AND sr.SERV_FILE_NO = s.FILE_NO
                     AND o.AMNT_TYPE = au.VALU
              )
              FROM dbo.[Order] o
             WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
               AND o.ORDR_STAT = '001'
               AND o.ORDR_CODE = @OrdrCode;
	      END 
      END      
       
      BEGIN/* آماده سازی ارسال پیام به مخاطبین */
	      DECLARE C$SndMsg3PJob CURSOR FOR
	         SELECT o.CODE, o.ORDR_TYPE
	           FROM dbo.[Order] o
	          WHERE o.ORDR_CODE = @OrdrCode
	            AND o.ORDR_STAT IN ( '001', '002', '005' )
	            AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */, '017' /* شغل حسابداری */)
   	   
	      OPEN [C$SndMsg3PJob];
	      L$Loop_C$SndMsg3PJob:
	      FETCH [C$SndMsg3PJob] INTO @TOrdrCode, @TOrdrType;
   	   
	      IF @@FETCH_STATUS <> 0
	         GOTO L$EndLoop_C$SndMsg3PJob;
   	      
         UPDATE dbo.[Order]
            SET ORDR_STAT = '002'
          WHERE CODE = @TOrdrCode;
         
         SET @XMessage = (
            SELECT @Rbid AS '@rbid'
                  ,@ChatID AS '@chatid'
                  ,opi.CMND_TEXT  AS '@cmndtext'
                  ,os.CODE AS '@ordrcode'
              FROM dbo.[Order] ot, dbo.[Order] os, dbo.Order_Process_InLineKeyboard opi
             WHERE ot.CODE = @OrdrCode
               AND os.CODE = @TOrdrCode
               AND opi.ROBO_RBID = @Rbid
               AND opi.TRGT_ORDR_TYPE = ot.ORDR_TYPE
               AND opi.TRGT_ORDR_STAT = ot.ORDR_STAT
               AND opi.SLAV_ORDR_TYPE = os.ORDR_TYPE
               AND opi.SLAV_ORDR_STAT = os.ORDR_STAT
               FOR XML PATH('RequestInLineQuery')
         )
         EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
         SET @XMessage = (
             SELECT 1 AS '@order',
                    @XMessage
                FOR XML PATH('InlineKeyboardMarkup')
         );         
         
         -- ثبت منوی برای خروجی نهایی
         UPDATE dbo.Order_Detail
            SET INLN_KEYB_DNRM = @XMessage,
                SEND_STAT = '001'
          WHERE ORDR_CODE = @TOrdrCode;         
         
         IF NOT EXISTS ( SELECT * FROM dbo.Personal_Robot_Job_Order WHERE ORDR_CODE = @TOrdrCode)
         BEGIN 
            SET @TDirPrjbCode = NULL;
            -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
            IF @TOrdrType IN ( '012', '017' )
            BEGIN
               SELECT @TDirPrjbCode = a.CODE
                 FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                WHERE a.PRBT_ROBO_RBID = @Rbid
                  AND a.JOB_CODE = b.CODE
                  AND b.ORDR_TYPE = @TOrdrType
                  AND o.CODE = @TOrdrCode
                  AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
            END 
            
            SELECT  @XMessage = ( 
               SELECT @TOrdrCode AS '@code' ,
                      @Rbid AS '@roborbid' ,
                      @TOrdrType '@type',
                      @TDirPrjbCode '@dirprjbcode'
              FOR XML PATH('Order'), ROOT('Process')
            );
            EXEC Send_Order_To_Personal_Robot_Job @XMessage;
         END 
         ELSE
         BEGIN
            UPDATE dbo.Personal_Robot_Job_Order
               SET ORDR_STAT = '001'
             WHERE ORDR_CODE = @TOrdrCode;
         END 
         GOTO L$Loop_C$SndMsg3PJob;
         L$EndLoop_C$SndMsg3PJob:
         CLOSE [C$SndMsg3PJob];
         DEALLOCATE [C$SndMsg3PJob];
	   END
      
	END 
	ELSE IF @OrdrType = '012' -- اطلاع رسانی
	BEGIN
	   SELECT @Oprt = @x.query('//Order').value('(Order/@oprt)[1]', 'VARCHAR(50)'),
	          @Valu = @x.query('//Order').value('(Order/@valu)[1]', 'NVARCHAR(MAX)');
	   
	   IF @Oprt IN ( 'discount', 'discountall' ) -- اطلاع رسانی به مشتریان جهت قرار دادن تخفیفات کالاهای جدید
	   BEGIN
	      /* اطلاع رسانی به مشتریانی که گزینه تخفیف را ثبت کرده اند */
	      -- بدست آوردن عکس مربوط به ثبت سفارش
         SELECT @TFileId = FILE_ID
           FROM dbo.Organ_Media
          WHERE ROBO_RBID = @Rbid
            AND RBCN_TYPE = '016'
            AND IMAG_TYPE = '002'
            AND STAT = '002';
         -- 
         INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), t.SRBT_SERV_FILE_NO, t.SRBT_ROBO_RBID, '012', GETDATE(), '001'
           FROM (
            SELECT DISTINCT a.SRBT_SERV_FILE_NO, a.SRBT_ROBO_RBID
              FROM dbo.Service_Robot_Product_Amazing_Notification a
             WHERE a.SRBT_ROBO_RBID = @Rbid
               AND @Oprt = 'discount'
               AND EXISTS (
                   SELECT *
                     FROM dbo.Robot_Product rp, dbo.Robot_Product_Discount rpd, dbo.SplitString(@Valu, ',') p
                    WHERE rp.ROBO_RBID = a.SRBT_ROBO_RBID
                      AND rp.CODE = a.RBPR_CODE
                      AND rp.ROBO_RBID = rpd.ROBO_RBID
                      AND rp.TARF_CODE = rpd.TARF_CODE
                      AND rp.TARF_CODE = p.Item
                      AND rpd.ACTV_TYPE = '002'
                   )
            -- 1399/10/22 * اضافه کردن گزینه ای برای اطلاع رسانی به همه مشتریان برای تخفیف روی کالا
            UNION ALL
            SELECT sr.SERV_FILE_NO, sr.ROBO_RBID
              FROM dbo.Service_Robot sr
             WHERE sr.ROBO_RBID = @Rbid
               AND sr.STAT = '002'
               AND @Oprt = 'discountall'
          ) T;
          
	      
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT o.CODE, '002', N'سامانه اطلاع رسانی بابت تخفیفات محصولات', @TFileId,
           (
               SELECT DISTINCT N'🔔 *' + df.DOMN_DESC + N' ( ' + CAST(rpd.OFF_PRCT AS VARCHAR(3)) + N' % ) *' + CHAR(10) 
                 FROM dbo.Robot_Product rp, dbo.Robot_Product_Discount rpd, dbo.SplitString(@Valu, ',') p, dbo.[D$OFTP] df
                WHERE rp.ROBO_RBID = rpd.ROBO_RBID
                  AND rp.TARF_CODE = rpd.TARF_CODE
                  AND rp.TARF_CODE = p.Item
                  AND rpd.ACTV_TYPE = '002'
                  AND df.VALU = rpd.OFF_TYPE
                  FOR XML PATH('')
           ) +  
           /*(
               SELECT N'👈 *' + rp.TARF_TEXT_DNRM + N'* ( کد محصول : ' + rp.TARF_CODE + N' ) ' + CHAR(10) --+ df.DOMN_DESC + N' (' + CAST(rpd.OFF_PRCT AS VARCHAR(3)) + N' % ) ' + CHAR(10) 
                 FROM dbo.Robot_Product rp, dbo.Robot_Product_Discount rpd, dbo.SplitString(@Valu, ',') p, dbo.[D$OFTP] df
                WHERE rp.ROBO_RBID = rpd.ROBO_RBID
                  AND rp.TARF_CODE = rpd.TARF_CODE
                  AND rp.TARF_CODE = p.Item
                  AND rpd.ACTV_TYPE = '002'
                  AND df.VALU = rpd.OFF_TYPE
                  FOR XML PATH('')
           )*/ + CHAR(10) + N'👈 جهت خرید می توانید محصول مورد نظر را انتخاب کرده و سفارش را انجام دهید '
           FROM dbo.[Order] o
          WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
            AND o.ORDR_STAT = '001'
            AND o.ORDR_CODE IS NULL;
         
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
            DECLARE C$SndMsg4PJob CURSOR FOR
               SELECT o.CODE, o.ORDR_TYPE
                 FROM dbo.[Order] o
                WHERE o.ORDR_STAT IN ( '001' )
                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
      	   
            OPEN [C$SndMsg4PJob];
            L$Loop_C$SndMsg4PJob:
            FETCH [C$SndMsg4PJob] INTO @TOrdrCode, @TOrdrType;
      	   
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop_C$SndMsg4PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '002'
             WHERE CODE = @TOrdrCode;
            
            SET @XMessage = (
               SELECT @Rbid AS '@rbid'
                     ,@ChatID AS '@chatid'
                     ,'*0*1#' AS '@ussdcode'
                     ,opi.CMND_TEXT  AS '@cmndtext'
                     ,os.CODE AS '@ordrcode'
                     ,@Valu AS '@param'
                 FROM dbo.[Order] os, dbo.Order_Process_InLineKeyboard opi
                WHERE os.CODE = @TOrdrCode
                  AND opi.ROBO_RBID = @Rbid                     
                  AND opi.TRGT_ORDR_TYPE = os.ORDR_TYPE
                  AND opi.TRGT_ORDR_STAT = os.ORDR_STAT
                  AND opi.SLAV_PATH = 'notiamazprod'
                  FOR XML PATH('RequestInLineQuery')
            )
            EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
            SET @XMessage = (
                SELECT 1 AS '@order',
                       @XMessage
                   FOR XML PATH('InlineKeyboardMarkup')
            );         
            
            -- ثبت منوی برای خروجی نهایی
            UPDATE dbo.Order_Detail
               SET INLN_KEYB_DNRM = @XMessage,
                   SEND_STAT = '001'
             WHERE ORDR_CODE = @TOrdrCode;         
            
            IF NOT EXISTS ( SELECT * FROM dbo.Personal_Robot_Job_Order WHERE ORDR_CODE = @TOrdrCode)
            BEGIN 
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            END 
            ELSE
            BEGIN
               UPDATE dbo.Personal_Robot_Job_Order
                  SET ORDR_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
            END 
            GOTO L$Loop_C$SndMsg4PJob;
            L$EndLoop_C$SndMsg4PJob:
            CLOSE [C$SndMsg4PJob];
            DEALLOCATE [C$SndMsg4PJob];
	      END 
	   END 
	   ELSE IF @Oprt = 'nomoreprodfromstor' -- تمام شدن کالا از قفسه موجودی ها
	   BEGIN
	      BEGIN/* اطلاع رسانی به حسابداری و انباردار جهت عدم موجودی کالا درون قفسه ها */
	      -- بدست آوردن عکس مربوط به عدم موجودی کالا درون قفسه ها
	         SELECT @TFileId = FILE_ID
	           FROM dbo.Organ_Media
	          WHERE ROBO_RBID = @Rbid
	            AND RBCN_TYPE = '018'
	            AND IMAG_TYPE = '002'
	            AND STAT = '002';
	         
	         -- 1399/05/05
	         -- تنظیم کردن درخواست جهت عدم موجودی کالا
	         SET @Oprt = dbo.GNRT_NVID_U();
	         
	         -- 
	         INSERT INTO dbo.[Order](CODE, /*ORDR_CODE,*/ SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, ORDR_DESC)
	         SELECT dbo.GNRT_NVID_U(), /*@OrdrCode,*/ pr.SERV_FILE_NO, pr.ROBO_RBID, '012', GETDATE(), '001', @Oprt
              FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj 
             WHERE j.CODE = prj.JOB_CODE 
               AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
               AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
               AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
               AND j.ROBO_RBID = @Rbid
               AND j.ORDR_TYPE IN ( '017' /* واحد حسابداری و واحد فروشندگان */, '018' /* واحد انبارداری */ )
               AND pr.STAT = '002'
               AND prj.STAT = '002';
	         
	         INSERT INTO dbo.Order_Detail
            (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
            SELECT o.CODE, '002', N'سامانه اطلاع رسانی بابت اتمام موجودی محصول برای فروش', @TFileId,
              (
                  SELECT N'🔔 *' + rp.TARF_TEXT_DNRM + N'* (کد محصول : ' + t.Item + N') ❌ ' + CHAR(10)                         
                    FROM dbo.Robot_Product rp, dbo.SplitString(@Valu, ',') T
                   WHERE rp.ROBO_RBID = @Rbid
                     AND rp.TARF_CODE = t.Item
                     FOR XML PATH('')
              ) + CHAR(10) + N'👈 لطفا جهت تامین موجودی قفسه محصولات اقدام نمایید '
              FROM dbo.[Order] o
             WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
               AND o.ORDR_STAT = '001'
               AND o.ORDR_DESC = @Oprt;
             --ORDER BY o.CRET_DATE DESC;
               --AND o.ORDR_CODE = @OrdrCode;
            
            BEGIN/* آماده سازی ارسال پیام به مخاطبین */
	            DECLARE C$SndMsg7PJob CURSOR FOR
	               SELECT o.CODE, o.ORDR_TYPE
	                 FROM dbo.[Order] o
	                WHERE o.ORDR_STAT IN ( '001' )
	                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
	                  AND o.ORDR_DESC = @Oprt;
	                  --AND o.ORDR_CODE = @OrdrCode;
         	   
	            OPEN [C$SndMsg7PJob];
	            L$Loop_C$SndMsg7PJob:
	            FETCH [C$SndMsg7PJob] INTO @TOrdrCode, @TOrdrType;
         	   
	            IF @@FETCH_STATUS <> 0
	               GOTO L$EndLoop_C$SndMsg7PJob;
         	      
               UPDATE dbo.[Order]
                  SET ORDR_STAT = '002'
                WHERE CODE = @TOrdrCode;
               
               -- ثبت منوی برای خروجی نهایی
               UPDATE dbo.Order_Detail
                  SET SEND_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
               
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به حسابدار، فروشنده، انباردار پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
               
               GOTO L$Loop_C$SndMsg7PJob;
               L$EndLoop_C$SndMsg7PJob:
               CLOSE [C$SndMsg7PJob];
               DEALLOCATE [C$SndMsg7PJob];
	         END
	      END
	   END 
	   ELSE IF @Oprt = 'alrmnumbprodfromstor' -- هشدار به حداقل رسیدن تعداد کالا از قفسه موجودی ها
	   BEGIN
	      BEGIN/* اطلاع رسانی به حسابداری و انباردار جهت عدم موجودی کالا درون قفسه ها */
	      -- بدست آوردن عکس مربوط به عدم موجودی کالا درون قفسه ها
	         SELECT @TFileId = FILE_ID
	           FROM dbo.Organ_Media
	          WHERE ROBO_RBID = @Rbid
	            AND RBCN_TYPE = '023'
	            AND IMAG_TYPE = '002'
	            AND STAT = '002';
	         
	         -- 1399/05/05
	         -- تنظیم کردن درخواست جهت عدم موجودی کالا
	         SET @Oprt = dbo.GNRT_NVID_U();
	         
	         -- 
	         INSERT INTO dbo.[Order](CODE, /*ORDR_CODE,*/ SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, ORDR_DESC)
	         SELECT dbo.GNRT_NVID_U(), /*@OrdrCode,*/ pr.SERV_FILE_NO, pr.ROBO_RBID, '012', GETDATE(), '001', @Oprt
              FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj 
             WHERE j.CODE = prj.JOB_CODE 
               AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
               AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
               AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
               AND j.ROBO_RBID = @Rbid
               AND j.ORDR_TYPE IN ( '017' /* واحد حسابداری و واحد فروشندگان */, '018' /* واحد انبارداری */ )
               AND pr.STAT = '002'
               AND prj.STAT = '002';
	         
	         INSERT INTO dbo.Order_Detail
            (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
            SELECT o.CODE, '002', N'سامانه اطلاع رسانی بابت هشدار جهت حداقل تعداد موجودی محصول برای فروش', @TFileId,
              (
                  SELECT N'🔔 *' + rp.TARF_TEXT_DNRM + N'* (کد محصول : ' + t.Item + N') ❌ ' + CHAR(10) + 
                         N'🔢 موجودی قفسه : ' + CAST(rp.CRNT_NUMB_DNRM AS VARCHAR(10)) + N' واحد' + CHAR(10)
                    FROM dbo.Robot_Product rp, dbo.SplitString(@Valu, ',') T
                   WHERE rp.ROBO_RBID = @Rbid
                     AND rp.TARF_CODE = t.Item
                     FOR XML PATH('')
              ) + CHAR(10) + N'👈 لطفا جهت تامین موجودی قفسه محصولات اقدام نمایید '
              FROM dbo.[Order] o
             WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
               AND o.ORDR_STAT = '001'
               AND o.ORDR_DESC = @Oprt;
             --ORDER BY o.CRET_DATE DESC;
               --AND o.ORDR_CODE = @OrdrCode;
            
            BEGIN/* آماده سازی ارسال پیام به مخاطبین */
	            DECLARE C$SndMsg8PJob CURSOR FOR
	               SELECT o.CODE, o.ORDR_TYPE
	                 FROM dbo.[Order] o
	                WHERE o.ORDR_STAT IN ( '001' )
	                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
	                  AND o.ORDR_DESC = @Oprt;
	                  --AND o.ORDR_CODE = @OrdrCode;
         	   
	            OPEN [C$SndMsg8PJob];
	            L$Loop_C$SndMsg8PJob:
	            FETCH [C$SndMsg8PJob] INTO @TOrdrCode, @TOrdrType;
         	   
	            IF @@FETCH_STATUS <> 0
	               GOTO L$EndLoop_C$SndMsg8PJob;
         	      
               UPDATE dbo.[Order]
                  SET ORDR_STAT = '002'
                WHERE CODE = @TOrdrCode;
               
               -- ثبت منوی برای خروجی نهایی
               UPDATE dbo.Order_Detail
                  SET SEND_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
               
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به حسابدار، فروشنده، انباردار پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
               
               GOTO L$Loop_C$SndMsg8PJob;
               L$EndLoop_C$SndMsg8PJob:
               CLOSE [C$SndMsg8PJob];
               DEALLOCATE [C$SndMsg8PJob];
	         END
	      END
	   END 
	   ELSE IF @Oprt = 'nomoreprodtosale' -- اطلاع رسانی به مدیر فروشگاه و حسابدار و انباردار جهت اتمام موجودی کالا	   
	   BEGIN
	      BEGIN/* اطلاع رسانی به حسابداری و انباردار جهت عدم موجودی کالا درون قفسه ها */
	      -- بدست آوردن عکس مربوط به عدم موجودی کالا درون قفسه ها
	         SELECT @TFileId = FILE_ID
	           FROM dbo.Organ_Media
	          WHERE ROBO_RBID = @Rbid
	            AND RBCN_TYPE = '018'
	            AND IMAG_TYPE = '002'
	            AND STAT = '002';
	         
	         -- 1399/05/05
	         -- تنظیم کردن درخواست جهت عدم موجودی کالا
	         SET @Oprt = dbo.GNRT_NVID_U();
	         
	         -- 
	         INSERT INTO dbo.[Order](CODE, /*ORDR_CODE,*/ SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, ORDR_DESC)
	         SELECT dbo.GNRT_NVID_U(), /*@OrdrCode,*/ pr.SERV_FILE_NO, pr.ROBO_RBID, '012', GETDATE(), '001', @Oprt
              FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj 
             WHERE j.CODE = prj.JOB_CODE 
               AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
               AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
               AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
               AND j.ROBO_RBID = @Rbid
               AND j.ORDR_TYPE IN ( '017' /* واحد حسابداری و واحد فروشندگان */, '018' /* واحد انبارداری */ )
               AND pr.STAT = '002'
               AND prj.STAT = '002';
	         
	         -- بدست آوردن شماره تعرفه محصولی که موجودی آن دیگر وجود ندارد
	         SET @TarfCode = @Valu
   	      
	         INSERT INTO dbo.Order_Detail
            (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
            SELECT o.CODE, '002', N'سامانه اطلاع رسانی بابت عدم وجود محصول برای فروش', @TFileId,
              (
                  SELECT N'🔔 *' + rp.TARF_TEXT_DNRM + N'* (کد محصول : ' + @TarfCode + N') ❌ ' + CHAR(10) + CHAR(10) +
                         N'لیست مشتریان متقاضی محصول:' + CHAR(10) + 
                         (
                           SELECT dbo.STR_FRMT_U(N'👤 *{0}* - *{1}* - *{2}* - *{3}*', CAST(sr.CHAT_ID AS VARCHAR(20)) + N',' + sr.NAME + N',' + sr.CELL_PHON + N',' + CAST(ISNULL(ps.CHCK_RQST_NUMB, 0) AS VARCHAR(3))) + CHAR(10)
                             FROM dbo.Service_Robot_Product_Signal ps, dbo.Service_Robot sr
                            WHERE sr.SERV_FILE_NO = ps.SRBT_SERV_FILE_NO
                              and sr.ROBO_RBID = ps.SRBT_ROBO_RBID
                              AND ps.SRBT_ROBO_RBID = @rbid
                              AND ps.TARF_CODE_DNRM = @TarfCode
                              AND ps.SEND_STAT IN ('002', '005')
                            ORDER BY ps.CRET_DATE DESC 
                              FOR XML PATH('')                            
                         )
                    FROM dbo.Robot_Product rp
                   WHERE rp.ROBO_RBID = @Rbid
                     AND rp.TARF_CODE = @TarfCode
                     FOR XML PATH('')
              ) + CHAR(10) + N'👈 لطفا جهت تامین موجودی قفسه محصولات اقدام نمایید '
              FROM dbo.[Order] o
             WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
               AND o.ORDR_STAT = '001'
               AND o.ORDR_DESC = @Oprt;
             --ORDER BY o.CRET_DATE DESC;
               --AND o.ORDR_CODE = @OrdrCode;
            
            BEGIN/* آماده سازی ارسال پیام به مخاطبین */
	            DECLARE C$SndMsg5PJob CURSOR FOR
	               SELECT o.CODE, o.ORDR_TYPE
	                 FROM dbo.[Order] o
	                WHERE o.ORDR_STAT IN ( '001' )
	                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
	                  AND o.ORDR_DESC = @Oprt;
	                  --AND o.ORDR_CODE = @OrdrCode;
         	   
	            OPEN [C$SndMsg5PJob];
	            L$Loop_C$SndMsg5PJob:
	            FETCH [C$SndMsg5PJob] INTO @TOrdrCode, @TOrdrType;
         	   
	            IF @@FETCH_STATUS <> 0
	               GOTO L$EndLoop_C$SndMsg5PJob;
         	      
               UPDATE dbo.[Order]
                  SET ORDR_STAT = '002'
                WHERE CODE = @TOrdrCode;
               
               -- ثبت منوی برای خروجی نهایی
               UPDATE dbo.Order_Detail
                  SET SEND_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
               
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به حسابدار، فروشنده، انباردار پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
               
               GOTO L$Loop_C$SndMsg5PJob;
               L$EndLoop_C$SndMsg5PJob:
               CLOSE [C$SndMsg5PJob];
               DEALLOCATE [C$SndMsg5PJob];
	         END
	      END
	   END 
	   ELSE IF @Oprt = 'addprodtostor' -- اضافه شدن کالا به موجودی قفسه ها
	   BEGIN
	      /* اطلاع رسانی به مشتریانی که گزینه کالای ناموجود را درخواست داده اند */
	      -- بدست آوردن عکس مربوط به اضافه شدن موجودی کالا
         SELECT @TFileId = FILE_ID
           FROM dbo.Organ_Media
          WHERE ROBO_RBID = @Rbid
            AND RBCN_TYPE = '022'
            AND IMAG_TYPE = '002'
            AND STAT = '002';
         -- 
         INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), t.SRBT_SERV_FILE_NO, t.SRBT_ROBO_RBID, '012', GETDATE(), '001'
           FROM (
            SELECT DISTINCT a.SRBT_SERV_FILE_NO, a.SRBT_ROBO_RBID
              FROM dbo.Service_Robot_Product_Signal a
             WHERE a.SRBT_ROBO_RBID = @Rbid
               AND a.TARF_CODE_DNRM = @Valu
               AND a.SEND_STAT IN ('002', '005')
          ) T;
          
	      
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT o.CODE, '002', N'سامانه اطلاع رسانی بابت اضافه شدن موجودی محصولات', @TFileId,
           (
               SELECT N'🔔 *' + RP.TARF_TEXT_DNRM + N' ( ' + RP.TARF_CODE + N' ) *' + CHAR(10) 
                 FROM dbo.Robot_Product rp
                WHERE rp.TARF_CODE = @Valu
                  AND rp.ROBO_RBID = @Rbid
                  FOR XML PATH('')
           ) +  
             CHAR(10) + N'👈 جهت خرید می توانید محصول مورد نظر را انتخاب کرده و سفارش را انجام دهید '
           FROM dbo.[Order] o
          WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
            AND o.ORDR_STAT = '001'
            AND o.ORDR_CODE IS NULL;
         
         -- 1399/05/05
         -- آزاد کردن درخواست اطلاع رسانی به مشتری جهت افزایش موجودی کالا
         UPDATE dbo.Service_Robot_Product_Signal
            SET SEND_STAT = '004'
          WHERE SRBT_ROBO_RBID = @Rbid
            AND TARF_CODE_DNRM = @Valu
            AND SEND_STAT IN ('002', '005');
         
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
            DECLARE C$SndMsg6PJob CURSOR FOR
               SELECT o.CODE, o.ORDR_TYPE
                 FROM dbo.[Order] o
                WHERE o.ORDR_STAT IN ( '001' )
                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
      	   
            OPEN [C$SndMsg6PJob];
            L$Loop_C$SndMsg6PJob:
            FETCH [C$SndMsg6PJob] INTO @TOrdrCode, @TOrdrType;
      	   
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop_C$SndMsg6PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '002'
             WHERE CODE = @TOrdrCode;
            
            SET @XMessage = (
               SELECT @Rbid AS '@rbid'
                     ,@ChatID AS '@chatid'
                     ,'*0*1#' AS '@ussdcode'
                     ,opi.CMND_TEXT  AS '@cmndtext'
                     ,os.CODE AS '@ordrcode'
                     ,@Valu AS '@param'
                 FROM dbo.[Order] os, dbo.Order_Process_InLineKeyboard opi
                WHERE os.CODE = @TOrdrCode
                  AND opi.ROBO_RBID = @Rbid                     
                  AND opi.TRGT_ORDR_TYPE = os.ORDR_TYPE
                  AND opi.TRGT_ORDR_STAT = os.ORDR_STAT
                  AND opi.SLAV_PATH = 'notinewprodstor'
                  FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
            SET @XMessage = (
                SELECT 1 AS '@order',
                       @XMessage
                   FOR XML PATH('InlineKeyboardMarkup')
            );         
            
            -- ثبت منوی برای خروجی نهایی
            UPDATE dbo.Order_Detail
               SET INLN_KEYB_DNRM = @XMessage,
                   SEND_STAT = '001'
             WHERE ORDR_CODE = @TOrdrCode;         
            
            IF NOT EXISTS ( SELECT * FROM dbo.Personal_Robot_Job_Order WHERE ORDR_CODE = @TOrdrCode)
            BEGIN 
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            END 
            ELSE
            BEGIN
               UPDATE dbo.Personal_Robot_Job_Order
                  SET ORDR_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
            END 
            GOTO L$Loop_C$SndMsg6PJob;
            L$EndLoop_C$SndMsg6PJob:
            CLOSE [C$SndMsg6PJob];
            DEALLOCATE [C$SndMsg6PJob];
	      END 
	   END 
	   ELSE IF @Oprt = 'addcredwlet' -- اضافه کردن مبلغ اعتبار به حساب کیف پول فروشگاه
	   BEGIN
	      /* اطلاع رسانی به مشتریانی که گزینه کالای ناموجود را درخواست داده اند */
	      -- بدست آوردن عکس مربوط به اضافه شدن موجودی کالا
         SELECT @TFileId = FILE_ID
           FROM dbo.Organ_Media
          WHERE ROBO_RBID = @Rbid
            AND RBCN_TYPE = '022'
            AND IMAG_TYPE = '002'
            AND STAT = '002';
         -- 
         INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), sr.SERV_FILE_NO, sr.ROBO_RBID, '012', GETDATE(), '001'
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @Chatid;
          
	      
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT o.CODE, '002', N'سامانه اطلاع رسانی بابت افزایش موجودی کیف پول اعتباری فروشگاه', @TFileId,
           (
               N'لطفا جهت افزایش کیف پول اعتباری خود اقدام فرمایید'               
           ) +  
             CHAR(10) 
           FROM dbo.[Order] o
          WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
            AND o.ORDR_STAT = '001'
            AND o.ORDR_CODE IS NULL;
         
         -- 1399/05/05
         -- آزاد کردن درخواست اطلاع رسانی به مشتری جهت افزایش موجودی کالا
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
            DECLARE C$SndMsg11PJob CURSOR FOR
               SELECT o.CODE, o.ORDR_TYPE
                 FROM dbo.[Order] o
                WHERE o.SRBT_ROBO_RBID = @Rbid
                  AND o.ORDR_STAT IN ( '001' )
                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
                  AND o.CHAT_ID = @Chatid;
      	   
            OPEN [C$SndMsg11PJob];
            L$Loop_C$SndMsg11PJob:
            FETCH [C$SndMsg11PJob] INTO @TOrdrCode, @TOrdrType;
      	   
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop_C$SndMsg11PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '002'
             WHERE CODE = @TOrdrCode;
            
            --SET @XMessage = (
            --   SELECT @Rbid AS '@rbid'
            --         ,@ChatID AS '@chatid'
            --         ,'*0*1#' AS '@ussdcode'
            --         ,opi.CMND_TEXT  AS '@cmndtext'
            --         ,os.CODE AS '@ordrcode'
            --         ,@Valu AS '@param'
            --     FROM dbo.[Order] os, dbo.Order_Process_InLineKeyboard opi
            --    WHERE os.CODE = @TOrdrCode
            --      AND opi.ROBO_RBID = @Rbid                     
            --      AND opi.TRGT_ORDR_TYPE = os.ORDR_TYPE
            --      AND opi.TRGT_ORDR_STAT = os.ORDR_STAT
            --      AND opi.SLAV_PATH = 'notinewprodstor'
            --      FOR XML PATH('RequestInLineQuery')
            --);
            --EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
            --SET @XMessage = (
            --    SELECT 1 AS '@order',
            --           @XMessage
            --       FOR XML PATH('InlineKeyboardMarkup')
            --);         
            
            -- ثبت منوی برای خروجی نهایی
            UPDATE dbo.Order_Detail
               SET --INLN_KEYB_DNRM = @XMessage,
                   SEND_STAT = '001'
             WHERE ORDR_CODE = @TOrdrCode;         
            
            IF NOT EXISTS ( SELECT * FROM dbo.Personal_Robot_Job_Order WHERE ORDR_CODE = @TOrdrCode)
            BEGIN 
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            END 
            ELSE
            BEGIN
               UPDATE dbo.Personal_Robot_Job_Order
                  SET ORDR_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
            END 
            GOTO L$Loop_C$SndMsg11PJob;
            L$EndLoop_C$SndMsg11PJob:
            CLOSE [C$SndMsg11PJob];
            DEALLOCATE [C$SndMsg11PJob];
         END
	   END 
	   ELSE IF @Oprt = 'poke4ordrrcpt' -- اطلاع رسانی به حسابداری برای بررسی رسید های جدید
	   BEGIN
	      -- 1399/09/08 * تمامی درخواست هایی که رسید پرداخت دارند را باید دادنه بررسی کنیم
	      IF EXISTS (
	         SELECT * 
	           FROM dbo.[Order] o, dbo.Order_State os 
	          WHERE o.CODE = os.ORDR_CODE
	            AND o.ORDR_STAT = '001'
	            AND os.CONF_STAT = '003'
	            AND os.AMNT_TYPE = '005' /* رسید پرداخت */)
	      BEGIN
	         SET @TOrdrCode = dbo.GNRT_NVID_U();
	         -- برای همه حسابداران فروشگاه درخواست ثبت میکنیم که بخواهیم اطلاع رسانی کنیم
	         INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, ORDR_DESC)
            SELECT dbo.GNRT_NVID_U(), pr.SERV_FILE_NO, pr.ROBO_RBID, '012', GETDATE(), '001', @TOrdrCode--N'اطلاع رسانی جهت بررسی رسیدهای پرداختی تایید نشده مشتریان'
              FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj 
             WHERE j.CODE = prj.JOB_CODE 
               AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
               AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
               AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
               AND j.ROBO_RBID = @Rbid
               AND j.ORDR_TYPE = '017'
               AND pr.STAT = '002'
               AND prj.STAT = '002';
	         
	         -- حال باید منوهای هر رسید را به حسابدار نشان دهیم
	         SET @XMessage = (
               SELECT @Rbid AS '@rbid'
                     ,'lessconfrcpt'  AS '@cmndtext'
                     ,'*0#' AS '@ussdcode'
                  FOR XML PATH('RequestInLineQuery')
            )
            EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
            SET @XMessage = (
                SELECT 1 AS '@order',
                       @XMessage
                   FOR XML PATH('InlineKeyboardMarkup')
            );
	         
	         -- متن پیام مربوط به درخواست اطلاع رسانی به حسابداری ها هم ثبت میکنیم
	         INSERT INTO dbo.Order_Detail
            (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC, INLN_KEYB_DNRM)
            SELECT o.CODE, '001', N'ثبت سند وصولی جدید بابت فروش آنلاین', @TFileId,
                  (
                     SELECT N'⏳ [ *سندهای تایید نشده* ]' + CHAR(10) +
                            N'[ تعداد سندها ] : *' + (SELECT REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(os.CODE)), 1), '.00', '') FROM dbo.[Order] o, dbo.Order_State os WHERE o.CODE = os.ORDR_CODE AND o.ORDR_STAT = '001' AND os.CONF_STAT = '003' AND os.AMNT_TYPE = '005') +  N'*' + CHAR(10) + 
	                         N'[ مبلغ سندها ] : *' + (SELECT REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM(o.DEBT_DNRM)), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' FROM dbo.[Order] o, dbo.[D$AMUT] au WHERE o.AMNT_TYPE = au.VALU AND o.ORDR_STAT = '001' AND EXISTS (SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.CONF_STAT = '003' AND os.AMNT_TYPE = '005') GROUP BY au.DOMN_DESC ) + CHAR(10) 
                  ), 
                  @XMessage
              FROM dbo.[Order] o
             WHERE o.ORDR_TYPE = '012' -- درخواست های اطلاع رسانی به واحد حسابداری
               AND o.ORDR_STAT = '001'
               AND o.ORDR_DESC = @TOrdrCode;
            
            SET @OrdrCode = @TOrdrCode;
            
            BEGIN/* آماده سازی ارسال پیام به مخاطبین */
	            DECLARE C$SndMsg12PJob CURSOR FOR
	               SELECT o.CODE, o.ORDR_TYPE
	                 FROM dbo.[Order] o
	                WHERE o.ORDR_DESC = @OrdrCode
	                  AND o.ORDR_STAT IN ( '001' )
	                  AND o.ORDR_TYPE IN ('012' /* شغل حسابداری */)
         	   
	            OPEN [C$SndMsg12PJob];
	            L$Loop_C$SndMsg12PJob:
	            FETCH [C$SndMsg12PJob] INTO @TOrdrCode, @TOrdrType;
         	   
	            IF @@FETCH_STATUS <> 0
	               GOTO L$EndLoop_C$SndMsg12PJob;
         	      
               UPDATE dbo.[Order]
                  SET ORDR_STAT = '002'
                WHERE CODE = @TOrdrCode;
               
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
               
               UPDATE dbo.[Order]
                  SET ORDR_STAT = '004',
                      ORDR_DESC += N' - ' + N'اطلاع رسانی جهت بررسی رسیدهای پرداختی تایید نشده مشتریان'
                WHERE CODE = @TOrdrCode;
               
               GOTO L$Loop_C$SndMsg12PJob;
               L$EndLoop_C$SndMsg12PJob:
               CLOSE [C$SndMsg12PJob];
               DEALLOCATE [C$SndMsg12PJob];
	         END
	      END 
	   END
	   ELSE IF @Oprt = 'poke4servordrfinl' /* این گزینه برای آن دسته از مشتریهایی هست که وصولی آنها ثبت شده و  */
	   BEGIN
	      -- بدست آوردن عکس مربوط به ثبت سفارش
	      SELECT @TFileId = FILE_ID
	        FROM dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND RBCN_TYPE = '026'
	         AND IMAG_TYPE = '002'
	         AND STAT = '002';
	      
	      -- پیدا کردن درخواست مربوط به مشتری که بتوانیم بان آن پیام تایید درخواست ارسال کنیم
	      SELECT @OrdrCode = o.CODE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode
	         AND o.ORDR_TYPE = '012'
	         AND o.CHAT_ID = @Chatid;
	      
	      -- ثبت پیام تایید درخواست برای مشتری
	      INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC, IMAG_PATH, INLN_KEYB_DNRM)
         SELECT o.CODE, '002', N'تاییدیه درخواست سفارش از واحد حسابداری',
                CAST(@Valu AS XML).query('.').value('(InlineKeyboardMarkup/@caption)[1]', 'NVARCHAR(1000)'),
                @TFileId, 
                CAST(@Valu AS XML)
           FROM dbo.[Order] o
          WHERE o.CODE = @OrdrCode;
	      
	      SELECT @TOrdrCode = @OrdrCode,
	             @TOrdrType = '012';
	      
	      SET @TDirPrjbCode = NULL;
         -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
         IF @TOrdrType IN ( '012' )
         BEGIN
            SELECT @TDirPrjbCode = a.CODE
              FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
             WHERE a.PRBT_ROBO_RBID = @Rbid
               AND a.JOB_CODE = b.CODE
               AND b.ORDR_TYPE = @TOrdrType
               AND o.CODE = @TOrdrCode
               AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
         END 
	      
	      SELECT  @XMessage = ( 
            SELECT @TOrdrCode AS '@code' ,
                   @Rbid AS '@roborbid' ,
                   @TOrdrType '@type',
                   @TDirPrjbCode '@dirprjbcode'
           FOR XML PATH('Order'), ROOT('Process')
         );
         EXEC Send_Order_To_Personal_Robot_Job @XMessage;	      
	   END
	   ELSE IF @Oprt = 'poke4servnotaprovrcptordr' /* این گزینه زمانی ارسال میشود که مشتری رسید نادرستی ارسال کرده باشد و واحد حسابداری آن را رد میکند */
	   BEGIN
	      -- بدست آوردن عکس مربوط به ثبت سفارش
	      SELECT @TFileId = FILE_ID
	        FROM dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND RBCN_TYPE = '009'
	         AND IMAG_TYPE = '002'
	         AND STAT = '002';
	      
	      INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, ORDR_CODE)
	      SELECT dbo.GNRT_NVID_U(), o.SRBT_SERV_FILE_NO, o.SRBT_ROBO_RBID, '012', GETDATE(), '001', @OrdrCode
	        FROM dbo.[Order] o
	       WHERE o.CODE = @OrdrCode
	         AND NOT EXISTS (
	                 SELECT *
	                   FROM dbo.[Order] o1
	                  WHERE o1.ORDR_CODE = o.CODE
	                    AND o1.ORDR_TYPE = '012'
	             );
	             
	      -- پیدا کردن درخواست مربوط به مشتری که بتوانیم بان آن پیام تایید درخواست ارسال کنیم
	      SELECT @OrdrCode = o.CODE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode
	         AND o.ORDR_TYPE = '012'
	         AND o.CHAT_ID = @Chatid;
	      
	      -- ثبت پیام تایید درخواست برای مشتری
	      INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC, IMAG_PATH)
         SELECT o.CODE, '001', N'عدم تایید رسید پرداختی از واحد حسابداری',
                @valu,
                @TFileId
           FROM dbo.[Order] o
          WHERE o.CODE = @OrdrCode;
	      
	      SELECT @TOrdrCode = @OrdrCode,
	             @TOrdrType = '012';
	      
	      SET @TDirPrjbCode = NULL;
         -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
         IF @TOrdrType IN ( '012' )
         BEGIN
            SELECT @TDirPrjbCode = a.CODE
              FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
             WHERE a.PRBT_ROBO_RBID = @Rbid
               AND a.JOB_CODE = b.CODE
               AND b.ORDR_TYPE = @TOrdrType
               AND o.CODE = @TOrdrCode
               AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
         END 
	      
	      SELECT  @XMessage = ( 
            SELECT @TOrdrCode AS '@code' ,
                   @Rbid AS '@roborbid' ,
                   @TOrdrType '@type',
                   @TDirPrjbCode '@dirprjbcode'
           FOR XML PATH('Order'), ROOT('Process')
         );
         EXEC Send_Order_To_Personal_Robot_Job @XMessage;
	   END
	   ELSE IF @Oprt = 'acptsupl' -- اطلاع رسانی به واحد نیروی انسانی بابت تایید تامین کننده
	   BEGIN
	      -- هدف از این قسمت ارسال پیام به واحد نیروی انسانی فروشگاه میباشد که تامین کننده را تایید کنند
	      SET @TOrdrCode = dbo.GNRT_NVID_U();
         -- برای همه حسابداران فروشگاه درخواست ثبت میکنیم که بخواهیم اطلاع رسانی کنیم
         INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, ORDR_DESC)
         SELECT dbo.GNRT_NVID_U(), pr.SERV_FILE_NO, pr.ROBO_RBID, '012', GETDATE(), '001', @TOrdrCode
           FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj , dbo.Service_Robot_Group g
          WHERE j.CODE = prj.JOB_CODE 
            AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
            AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
            AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
            AND j.ROBO_RBID = @Rbid
            AND j.ORDR_TYPE = '025'
            AND pr.STAT = '002'
            AND prj.STAT = '002'
            AND pr.SERV_FILE_NO = g.SRBT_SERV_FILE_NO
            AND pr.ROBO_RBID = g.SRBT_ROBO_RBID
            AND g.GROP_GPID = 136 -- دسترسی به گروه نیروی انسانی
            AND g.STAT = '002';
         
         -- حال باید منوهای هر رسید را به حسابدار نشان دهیم
         SET @XMessage = (
            SELECT @Rbid AS '@rbid'
                  ,@Chatid AS '@chatid'
                  ,'lessconfsupl'  AS '@cmndtext'
                  ,'*0#' AS '@ussdcode'
               FOR XML PATH('RequestInLineQuery')
         )
         EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
         SET @XMessage = (
             SELECT 1 AS '@order',
                    @XMessage
                FOR XML PATH('InlineKeyboardMarkup')
         );
         
         -- متن پیام مربوط به درخواست اطلاع رسانی به حسابداری ها هم ثبت میکنیم
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC, INLN_KEYB_DNRM)
         SELECT o.CODE, '001', N'درخواست همکاری تامین کننده', @TFileId,
               (
                  SELECT sr.NAME + N' درخواست عضو شدن در گروه تامین کنندگان را دارد. *آیا شما میخواهید با ایشان رده همکاری ایجاد کنید؟*'
                    FROM dbo.Service_Robot sr
                   WHERE sr.ROBO_RBID = @Rbid
                     AND sr.CHAT_ID = @Chatid -- اطلاعات درخواست کننده
               ), 
               @XMessage
           FROM dbo.[Order] o
          WHERE o.ORDR_TYPE = '012' -- درخواست های اطلاع رسانی به واحد پذیرش انلاین پرسنل نیروی انسانی
            AND o.ORDR_STAT = '001'
            AND o.ORDR_DESC = @TOrdrCode;
         
         SET @OrdrCode = @TOrdrCode;
         
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
            DECLARE C$SndMsg13PJob CURSOR FOR
               SELECT o.CODE, o.ORDR_TYPE
                 FROM dbo.[Order] o
                WHERE o.ORDR_DESC = @OrdrCode
                  AND o.ORDR_STAT IN ( '001' )
                  AND o.ORDR_TYPE IN ('012' /* شغل پذیرش انلاین - نیروی انسانی */)
      	   
            OPEN [C$SndMsg13PJob];
            L$Loop_C$SndMsg13PJob:
            FETCH [C$SndMsg13PJob] INTO @TOrdrCode, @TOrdrType;
      	   
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop_C$SndMsg13PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '002'
             WHERE CODE = @TOrdrCode;
            
            SET @TDirPrjbCode = NULL;
            -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
            IF @TOrdrType IN ( '012' )
            BEGIN
               SELECT @TDirPrjbCode = a.CODE
                 FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                WHERE a.PRBT_ROBO_RBID = @Rbid
                  AND a.JOB_CODE = b.CODE
                  AND b.ORDR_TYPE = @TOrdrType
                  AND o.CODE = @TOrdrCode
                  AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
                  AND EXISTS (
                      SELECT *
                        FROM dbo.Service_Robot_Group g
                       WHERE g.SRBT_SERV_FILE_NO = a.PRBT_SERV_FILE_NO
                         AND g.SRBT_ROBO_RBID = a.PRBT_ROBO_RBID
                         AND g.GROP_GPID = 136 -- دسترسی به نیروی انسانی
                         AND g.STAT = '002'  
                  );
            END 
            
            SELECT  @XMessage = ( 
               SELECT @TOrdrCode AS '@code' ,
                      @Rbid AS '@roborbid' ,
                      @TOrdrType '@type',
                      @TDirPrjbCode '@dirprjbcode'
              FOR XML PATH('Order'), ROOT('Process')
            );
            EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            
            UPDATE dbo.[Order]
               SET ORDR_STAT = '004',
                   ORDR_DESC += N' - ' + N'اطلاع رسانی جهت بررسی درخواست تامین کالا برای فروشگاه'
             WHERE CODE = @TOrdrCode;
            
            GOTO L$Loop_C$SndMsg13PJob;
            L$EndLoop_C$SndMsg13PJob:
            CLOSE [C$SndMsg13PJob];
            DEALLOCATE [C$SndMsg13PJob];
         END
	   END 
	   ELSE IF @Oprt = 'downloadfile' -- ارسال فابل محصولات و خدمات مجازی
	   BEGIN
	      -- ثبت درخواست اطلاع رسانی
	      INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, ORDR_CODE)
	      SELECT dbo.GNRT_NVID_U(), o.SRBT_SERV_FILE_NO, o.SRBT_ROBO_RBID, '012', GETDATE(), '001', @OrdrCode
	        FROM dbo.[Order] o
	       WHERE o.CODE = @OrdrCode
	         AND NOT EXISTS (
	                 SELECT *
	                   FROM dbo.[Order] o1
	                  WHERE o1.ORDR_CODE = o.CODE
	                    AND o1.ORDR_TYPE = '012'
	             );
	             
	      SELECT @TOrdrCode = NULL, @TOrdrType = NULL;
	      -- پیدا کردن درخواست اطلاع رسانی مشتری
	      SELECT @TOrdrCode = o.CODE, @TOrdrType = o.ORDR_TYPE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode
	         AND o.CHAT_ID = @Chatid
	         AND o.ORDR_TYPE = '012';	      
	      
	      -- ثبت پیام تایید درخواست برای مشتری
	      INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC, IMAG_PATH)
         SELECT @TOrdrCode, d.FILE_TYPE, N'دریافت فایلهای مربوط به سفارش شما',
                ISNULL(d.FILE_DESC, od.ORDR_DESC),
                d.FILE_ID
           FROM dbo.Order_Detail od, dbo.Robot_Product_Download d
          WHERE od.ORDR_CODE = @OrdrCode
            AND od.TARF_CODE = d.TARF_CODE
            AND d.STAT = '002'
            AND d.DNLD_TYPE = @Valu;
	      
	      SET @TDirPrjbCode = NULL;
         -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
         IF @TOrdrType IN ( '012' )
         BEGIN
            SELECT @TDirPrjbCode = a.CODE
              FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
             WHERE a.PRBT_ROBO_RBID = @Rbid
               AND a.JOB_CODE = b.CODE
               AND b.ORDR_TYPE = @TOrdrType
               AND o.CODE = @TOrdrCode
               AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
         END 
	      
	      SELECT  @XMessage = ( 
            SELECT @TOrdrCode AS '@code' ,
                   @Rbid AS '@roborbid' ,
                   @TOrdrType '@type',
                   @TDirPrjbCode '@dirprjbcode'
           FOR XML PATH('Order'), ROOT('Process')
         );
         EXEC Send_Order_To_Personal_Robot_Job @XMessage;
         
         UPDATE dbo.[Order]
            SET ORDR_STAT = '004'
          WHERE CODE = @TOrdrCode;
	   END 
	   ELSE IF @Oprt = 'withdrawcashwlet' -- موقعیت برداشت مبلغ نقدی از حساب کیف پول فروشگاه
	   BEGIN
	      /* اطلاع رسانی به مشتریانی که گزینه کالای ناموجود را درخواست داده اند */
	      -- بدست آوردن عکس مربوط به اضافه شدن موجودی کالا
         SELECT @TFileId = FILE_ID
           FROM dbo.Organ_Media
          WHERE ROBO_RBID = @Rbid
            AND RBCN_TYPE = '022'
            AND IMAG_TYPE = '002'
            AND STAT = '002';
         -- 
         INSERT  INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), sr.SERV_FILE_NO, sr.ROBO_RBID, '012', GETDATE(), '001'
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @Chatid;
          
	      
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT o.CODE, '002', N'سامانه اطلاع رسانی بابت قابلیت برداشت از کیف پول نقدینگی فروشگاه', @TFileId,
         (
            SELECT N'لطفا جهت برداشت مبلغ کیف پول نقدینگی خود اقدام فرمایید' + CHAR(10) + CHAR(10) +
                   N'مبلغ موجودی شما : ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, w.AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ]* ' + CHAR(10) + 
                   N'نحوه درخواست برداشت مبلغ *👤 ورود به حساب کاربری* < *💰 امور مالی* < *💶 درخواست وجه*'
              FROM dbo.Wallet w, dbo.[D$AMUT] au
             WHERE w.SRBT_ROBO_RBID = @Rbid
               AND w.CHAT_ID = @Chatid
               AND w.WLET_TYPE = '002'
               AND o.AMNT_TYPE = au.VALU
         ) +  
          CHAR(10) 
         FROM dbo.[Order] o
        WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
          AND o.ORDR_STAT = '001'
          AND o.ORDR_CODE IS NULL;
          
         -- 1399/05/05
         -- آزاد کردن درخواست اطلاع رسانی به مشتری جهت افزایش موجودی کالا
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
            DECLARE C$SndMsg14PJob CURSOR FOR
               SELECT o.CODE, o.ORDR_TYPE
                 FROM dbo.[Order] o
                WHERE o.SRBT_ROBO_RBID = @Rbid
                  AND o.ORDR_STAT IN ( '001' )
                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
                  AND o.CHAT_ID = @Chatid;
      	   
            OPEN [C$SndMsg14PJob];
            L$Loop_C$SndMsg14PJob:
            FETCH [C$SndMsg14PJob] INTO @TOrdrCode, @TOrdrType;
      	   
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop_C$SndMsg14PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '002'
             WHERE CODE = @TOrdrCode;
            
            -- ثبت منوی برای خروجی نهایی
            UPDATE dbo.Order_Detail
               SET SEND_STAT = '001'
             WHERE ORDR_CODE = @TOrdrCode;         
            
            IF NOT EXISTS ( SELECT * FROM dbo.Personal_Robot_Job_Order WHERE ORDR_CODE = @TOrdrCode)
            BEGIN 
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            END 
            ELSE
            BEGIN
               UPDATE dbo.Personal_Robot_Job_Order
                  SET ORDR_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
            END 
            
            UPDATE dbo.[Order]
               SET ORDR_STAT = '004'
             WHERE CODE = @TOrdrCode;
             
            GOTO L$Loop_C$SndMsg14PJob;
            L$EndLoop_C$SndMsg14PJob:
            CLOSE [C$SndMsg14PJob];
            DEALLOCATE [C$SndMsg14PJob];
         END
	   END 
	   ELSE IF @Oprt = 'shopnocrdtwlet' -- هشدار به مدیر فروشگاه جهت عدم اعتبار فروشگاه
	   BEGIN	
	      -- درج رکورد در جدول اطلاع رسانی به مشتریان
	      INSERT INTO dbo.Service_Robot_Amazing_Notification ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,CODE ,TYPE ,SEND_WITH_APP )
	      SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, dbo.GNRT_NVID_U(), '001', '002'
	        FROM dbo.Service_Robot sr
	       WHERE sr.ROBO_RBID = @Rbid
	         AND sr.CHAT_ID = @Chatid
	         AND NOT EXISTS (
	                 SELECT *
	                   FROM dbo.Service_Robot_Amazing_Notification a
	                  WHERE a.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	                    AND a.SRBT_ROBO_RBID = sr.ROBO_RBID
	                    AND a.STAT = '002'
	             );
	         
	      -- بدست آوردن عکس مربوط به اطلاع رسانی به مدیر فروشگاه
         SELECT @TFileId = FILE_ID
           FROM dbo.Organ_Media
          WHERE ROBO_RBID = @Rbid
            AND RBCN_TYPE = '024'
            AND IMAG_TYPE = '002'
            AND STAT = '002';
         
         -- 1399/10/26 * بدست آوردن کد مدیر فروشگاه
         SELECT TOP 1 @AdminChatId = sr.CHAT_ID
           FROM dbo.Service_Robot sr, dbo.Service_Robot_Group g
          WHERE sr.SERV_FILE_NO = g.SRBT_SERV_FILE_NO
            AND sr.ROBO_RBID = g.SRBT_ROBO_RBID
            AND sr.ROBO_RBID = @Rbid
            AND g.GROP_GPID = 131
            AND g.STAT = '002';
         
         --
         INSERT INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), sr.SERV_FILE_NO, sr.ROBO_RBID, '012', GETDATE(), '001'
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @AdminChatid;          
	      
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT o.CODE, '002', N'سامانه اطلاع رسانی بابت عدم اعتبار کافی کیف پول اعتباری فروشگاه', @TFileId,
         (
            SELECT N'لطفا جهت افزایش مبلغ کیف پول اعتباری خود اقدام فرمایید' + CHAR(10) + CHAR(10) +
                   N'مبلغ موجودی شما : ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, w.AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ]* ' + CHAR(10) + 
                   N'نحوه افزایش شارژ مبلغ *👥 امور فروشندگان* < *💰 امور مالی* < *🔋 افزایش مبلغ کیف پول* > *💳 کیف پول اعتباری*'
              FROM dbo.Wallet w, dbo.[D$AMUT] au
             WHERE w.SRBT_ROBO_RBID = @Rbid
               AND w.CHAT_ID = @AdminChatid
               AND w.WLET_TYPE = '001'
               AND o.AMNT_TYPE = au.VALU
         ) +  
          CHAR(10) 
         FROM dbo.[Order] o
        WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
          AND o.ORDR_STAT = '001'
          AND o.CHAT_ID = @AdminChatId
          AND o.ORDR_CODE IS NULL;
          
         -- 1399/05/05
         -- آزاد کردن درخواست اطلاع رسانی به مشتری جهت افزایش موجودی کالا
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
            DECLARE C$SndMsg15PJob CURSOR FOR
               SELECT o.CODE, o.ORDR_TYPE
                 FROM dbo.[Order] o
                WHERE o.SRBT_ROBO_RBID = @Rbid
                  AND o.ORDR_STAT IN ( '001' )
                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
                  AND o.CHAT_ID = @AdminChatid;
      	   
            OPEN [C$SndMsg15PJob];
            L$Loop_C$SndMsg15PJob:
            FETCH [C$SndMsg15PJob] INTO @TOrdrCode, @TOrdrType;
      	   
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop_C$SndMsg15PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '002'
             WHERE CODE = @TOrdrCode;
            
            -- ثبت منوی برای خروجی نهایی
            UPDATE dbo.Order_Detail
               SET SEND_STAT = '001'
             WHERE ORDR_CODE = @TOrdrCode;         
            
            IF NOT EXISTS ( SELECT * FROM dbo.Personal_Robot_Job_Order WHERE ORDR_CODE = @TOrdrCode)
            BEGIN 
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            END 
            ELSE
            BEGIN
               UPDATE dbo.Personal_Robot_Job_Order
                  SET ORDR_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
            END 
            
            UPDATE dbo.[Order]
               SET ORDR_STAT = '004'
             WHERE CODE = @TOrdrCode;
             
            GOTO L$Loop_C$SndMsg15PJob;
            L$EndLoop_C$SndMsg15PJob:
            CLOSE [C$SndMsg15PJob];
            DEALLOCATE [C$SndMsg15PJob];
         END
	   END
	   ELSE IF @Oprt = 'alrtchngcrnc' -- هشدار به مدیر فروشگاه جهت عدم اعتبار فروشگاه
	   BEGIN	
	      -- درج رکورد در جدول اطلاع رسانی به مشتریان
	      -- بدست آوردن عکس مربوط به اطلاع رسانی به مدیر فروشگاه
         SELECT @TFileId = FILE_ID
           FROM dbo.Organ_Media
          WHERE ROBO_RBID = @Rbid
            AND RBCN_TYPE = '028'
            AND IMAG_TYPE = '002'
            AND STAT = '002';
         --
         INSERT INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), sr.SERV_FILE_NO, sr.ROBO_RBID, '012', GETDATE(), '001'
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND EXISTS(
                SELECT *
                  FROM dbo.Personal_Robot_Job pj
                 WHERE pj.PRBT_ROBO_RBID = @Rbid
                   AND pj.CHAT_ID = sr.CHAT_ID
                   AND pj.JOB_CODE = 36
                   AND pj.STAT = '002'
            )
	      
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , IMAG_PATH, ORDR_DESC)
         SELECT o.CODE, '002', N'سامانه اطلاع رسانی نرخ ارزها', @TFileId,
         (
            SELECT N'🔵 *' + d.DOMN_DESC + N'*' + CHAR(10) + 
                   N'🌐 مرجع اطلاعات : *' + cs.WEB_SITE + N'*' + CHAR(10) + CHAR(10) + 
                   (
                     SELECT N'📊 ' + rc.CRNC_NAME + N'   ---  *'+ REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, rc.CRNT_AMNT_DNRM), 1), '.00', '') + N'* ریال ' + CHAR(10)
                       FROM dbo.Robot_Currency rc
                      WHERE rc.RBCS_CODE = cs.Code
                        AND rc.UPDT_STAT = '002'
                      ORDER BY rc.RWNO
                        FOR XML PATH('')
                   ) 
              FROM dbo.Robot_Currency_Source cs, dbo.[D$CSOR] d
             WHERE cs.ROBO_RBID = @Rbid
               AND cs.TYPE = d.VALU
               AND EXISTS (
                   SELECT *
                     FROM dbo.Robot_Currency rc
                    WHERE rc.RBCS_CODE = cs.CODE
                      AND rc.UPDT_STAT = '002'
               )
             ORDER BY cs.TYPE               
              FOR XML PATH('')
         ) + CHAR(10) 
           + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
           + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)) +CHAR(10) 
         FROM dbo.[Order] o
        WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
          AND o.ORDR_STAT = '001'
          AND o.ORDR_CODE IS NULL;
          
         -- 1399/05/05
         -- آزاد کردن درخواست اطلاع رسانی به مشتری جهت افزایش موجودی کالا
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
            DECLARE C$SndMsg16PJob CURSOR FOR
               SELECT o.CODE, o.ORDR_TYPE
                 FROM dbo.[Order] o
                WHERE o.SRBT_ROBO_RBID = @Rbid
                  AND o.ORDR_STAT IN ( '001' )
                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
                  AND o.ORDR_CODE IS NULL;
      	   
            OPEN [C$SndMsg16PJob];
            L$Loop_C$SndMsg16PJob:
            FETCH [C$SndMsg16PJob] INTO @TOrdrCode, @TOrdrType;
      	   
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop_C$SndMsg16PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '002'
             WHERE CODE = @TOrdrCode;
            
            -- ثبت منوی برای خروجی نهایی
            UPDATE dbo.Order_Detail
               SET SEND_STAT = '001'
             WHERE ORDR_CODE = @TOrdrCode;         
            
            IF NOT EXISTS ( SELECT * FROM dbo.Personal_Robot_Job_Order WHERE ORDR_CODE = @TOrdrCode)
            BEGIN 
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            END 
            ELSE
            BEGIN
               UPDATE dbo.Personal_Robot_Job_Order
                  SET ORDR_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
            END 
            
            UPDATE dbo.[Order]
               SET ORDR_STAT = '004'
             WHERE CODE = @TOrdrCode;
             
            GOTO L$Loop_C$SndMsg16PJob;
            L$EndLoop_C$SndMsg16PJob:
            CLOSE [C$SndMsg16PJob];
            DEALLOCATE [C$SndMsg16PJob];
         END
	   END
	   ELSE IF @Oprt = 'sendinvoice' -- ارسال فاکتور برای مشتری
	   BEGIN
         INSERT INTO dbo.[Order](CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT)
         SELECT dbo.GNRT_NVID_U(), sr.SERV_FILE_NO, sr.ROBO_RBID, '012', GETDATE(), '001'
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND EXISTS(
                SELECT *
                  FROM dbo.Personal_Robot_Job pj
                 WHERE pj.PRBT_ROBO_RBID = @Rbid
                   AND pj.CHAT_ID = sr.CHAT_ID
                   AND pj.JOB_CODE = 36
                   AND pj.STAT = '002'
            );
	      
	      SET @XMessage = (
	          SELECT r.TKON_CODE AS '@token',
	                 '*0*2#' AS 'Message/@ussd',
	                 @Chatid AS 'Message/@chatid',
	                 @OrdrCode AS 'Message/Text/@ordrcode',
	                 'show' 
	            FROM dbo.Robot r
	           WHERE r.RBID = @Rbid
	             FOR XML PATH('Robot')
	      );
	      EXEC dbo.AnarShop_Analisis_Message_P @X = @XMessage, @XResult = @XRet OUTPUT;	      
	      
         INSERT INTO dbo.Order_Detail
         (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC, INLN_KEYB_DNRM)
         SELECT o.CODE, '001', N'ارسال فاکتور فروش',
         (
            SELECT CAST(@XRet.query('//Message').value('.', 'NVARCHAR(MAX)') AS XML).query('InlineKeyboardMarkup').value('(InlineKeyboardMarkup/@caption)[1]', 'NVARCHAR(MAX)')
         ),
         @XRet
         FROM dbo.[Order] o
        WHERE o.ORDR_TYPE = '012' -- درخواست های اعلام ها
          AND o.ORDR_STAT = '001'
          AND o.ORDR_CODE IS NULL;
          
         -- 1399/05/05
         -- آزاد کردن درخواست اطلاع رسانی به مشتری جهت افزایش موجودی کالا
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
            DECLARE C$SndMsg17PJob CURSOR FOR
               SELECT o.CODE, o.ORDR_TYPE
                 FROM dbo.[Order] o
                WHERE o.SRBT_ROBO_RBID = @Rbid
                  AND o.ORDR_STAT IN ( '001' )
                  AND o.ORDR_TYPE IN ('012' /* درخواست اعلام ها */)
                  AND o.ORDR_CODE IS NULL;
      	   
            OPEN [C$SndMsg17PJob];
            L$Loop_C$SndMsg17PJob:
            FETCH [C$SndMsg17PJob] INTO @TOrdrCode, @TOrdrType;
      	   
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop_C$SndMsg17PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '002'
             WHERE CODE = @TOrdrCode;            
            
            IF NOT EXISTS ( SELECT * FROM dbo.Personal_Robot_Job_Order WHERE ORDR_CODE = @TOrdrCode)
            BEGIN 
               SET @TDirPrjbCode = NULL;
               -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
               IF @TOrdrType IN ( '012' )
               BEGIN
                  SELECT @TDirPrjbCode = a.CODE
                    FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                   WHERE a.PRBT_ROBO_RBID = @Rbid
                     AND a.JOB_CODE = b.CODE
                     AND b.ORDR_TYPE = @TOrdrType
                     AND o.CODE = @TOrdrCode
                     AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
               END 
               
               SELECT  @XMessage = ( 
                  SELECT @TOrdrCode AS '@code' ,
                         @Rbid AS '@roborbid' ,
                         @TOrdrType '@type',
                         @TDirPrjbCode '@dirprjbcode'
                 FOR XML PATH('Order'), ROOT('Process')
               );
               EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            END 
            ELSE
            BEGIN
               UPDATE dbo.Personal_Robot_Job_Order
                  SET ORDR_STAT = '001'
                WHERE ORDR_CODE = @TOrdrCode;
            END 
            
            UPDATE dbo.[Order]
               SET ORDR_STAT = '004'
             WHERE CODE = @TOrdrCode;
             
            GOTO L$Loop_C$SndMsg17PJob;
            L$EndLoop_C$SndMsg17PJob:
            CLOSE [C$SndMsg17PJob];
            DEALLOCATE [C$SndMsg17PJob];
         END
	   END 
	END 
	ELSE IF @OrdrType = '026' -- پیام های تبلیغاتی
	BEGIN
	   SELECT @Oprt = @x.query('//Order').value('(Order/@oprt)[1]', 'VARCHAR(50)'),
	          @Valu = @x.query('//Order').value('(Order/@valu)[1]', 'NVARCHAR(MAX)');
	   
	   IF @Oprt = 'aprvadv'
	   BEGIN
	      -- چک کردن اینکه درخواست اطلاع رسانی به ارسال کننده تبلیغ وجود دارد یا خیر
         SELECT @TOrdrCode = o.CODE
           FROM dbo.[Order] o
          where o.ORDR_CODE = @OrdrCode
            AND o.ORDR_TYPE = '012';
         
         -- اگر درخواست اطلاع رسانی به تبلیغ کننده وجود نداشته باشد
         IF ISNULL(@TOrdrCode, 0) = 0
         BEGIN
            SET @XMessage = (
                SELECT 12 AS '@subsys',
                       '012' AS '@ordrtype',
                       '000' AS '@typecode', 
                       @ChatId AS '@chatid',
                       @Rbid AS '@rbid',
                       0 AS '@ordrcode'
                   FOR XML PATH('Action')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XMessage, -- xml
               @xRet = @XMessage OUTPUT; -- xml
            
            
            
            SELECT @RsltCode = @XMessage.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)');
            IF(@RsltCode = '002')
            BEGIN
               -- بدست آوردن شماره درخواست اطلاع رسانی
               SELECT @TOrdrCode = @XMessage.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
               
               -- قراردادن شماره درخواست ارسال پیام تبلیغات درون درخواست اطلاع رسانی
               UPDATE dbo.[Order]
                  SET ORDR_CODE = @OrdrCode
                WHERE CODE = @TOrdrCode;
                
               INSERT INTO dbo.Order_Detail
               ( ORDR_CODE ,ELMN_TYPE ,ORDR_DESC, ORDR_CMNT, IMAG_PATH )
               SELECT TOP 1 @TOrdrCode, a.MESG_TYPE, 
                      N'✅ تایید درخواست ارسال پیام تبلیغات',
                      a.MESG_TEXT,
                      a.[FILE_ID]
                 FROM dbo.Service_Robot_Replay_Message a
                WHERE a.SRBT_ROBO_RBID = @Rbid
                  AND a.ORDT_ORDR_CODE = @OrdrCode -- شماره درخواست ارسال تبلیغات
                  AND a.CONF_STAT = '002'
                  AND a.HEDR_CODE = @Valu;               
            END
         END
         
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
	         DECLARE C$SndMsg9PJob CURSOR FOR
	            SELECT o.CODE, o.ORDR_TYPE
	              FROM dbo.[Order] o
	             WHERE o.ORDR_CODE = @OrdrCode
	               AND o.ORDR_STAT IN ( '001' )
	               AND o.ORDR_TYPE IN ('012' /* درخواست اطلاع رسانی ها */)
      	   
	         OPEN [C$SndMsg9PJob];
	         L$Loop_C$SndMsg9PJob:
	         FETCH [C$SndMsg9PJob] INTO @TOrdrCode, @TOrdrType;
      	   
	         IF @@FETCH_STATUS <> 0
	            GOTO L$EndLoop_C$SndMsg9PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = CASE ORDR_STAT WHEN '001' THEN '002' ELSE ORDR_STAT END
             WHERE CODE = @TOrdrCode;
            
            SET @XMessage = (
               SELECT @Rbid AS '@rbid'
                     ,@UssdCode AS '@ussdcode'
                     ,@ChatID AS '@chatid'
                     ,'lesssndraprvadv'  AS '@cmndtext'
                     ,@TOrdrCode AS '@ordrcode'
                     ,@Valu AS '@param'
                 FOR XML PATH('RequestInLineQuery')
            )
            EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
            SET @XMessage = (
                SELECT 1 AS '@order',
                       @XMessage
                   FOR XML PATH('InlineKeyboardMarkup')
            );         
            
            -- ثبت منوی برای خروجی نهایی
            UPDATE dbo.Order_Detail
               SET INLN_KEYB_DNRM = @XMessage
             WHERE ORDR_CODE = @TOrdrCode;         
            
            SET @TDirPrjbCode = NULL;
            -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
            IF @TOrdrType IN ( '012' )
            BEGIN
               SELECT @TDirPrjbCode = a.CODE
                 FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                WHERE a.PRBT_ROBO_RBID = @Rbid
                  AND a.JOB_CODE = b.CODE
                  AND b.ORDR_TYPE = @TOrdrType
                  AND o.CODE = @TOrdrCode
                  AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
            END 
            
            SELECT  @XMessage = ( 
               SELECT @TOrdrCode AS '@code' ,
                      @Rbid AS '@roborbid' ,
                      @TOrdrType '@type',
                      @TDirPrjbCode '@dirprjbcode'
              FOR XML PATH('Order'), ROOT('Process')
            );
            EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            
            --UPDATE dbo.[Order]
            --   SET ORDR_STAT = '004'
            -- WHERE CODE = @TOrdrCode;
            
            GOTO L$Loop_C$SndMsg9PJob;
            L$EndLoop_C$SndMsg9PJob:
            CLOSE [C$SndMsg9PJob];
            DEALLOCATE [C$SndMsg9PJob];
	      END 
	   END 
	   ELSE IF @Oprt = 'disaprvadv'
	   BEGIN
	      -- چک کردن اینکه درخواست اطلاع رسانی به ارسال کننده تبلیغ وجود دارد یا خیر
         SELECT @TOrdrCode = o.CODE
           FROM dbo.[Order] o
          where o.ORDR_CODE = @OrdrCode
            AND o.ORDR_TYPE = '012';
         
         -- اگر درخواست اطلاع رسانی به تبلیغ کننده وجود نداشته باشد
         IF ISNULL(@TOrdrCode, 0) = 0
         BEGIN
            SET @XMessage = (
                SELECT 12 AS '@subsys',
                       '012' AS '@ordrtype',
                       '000' AS '@typecode', 
                       @ChatId AS '@chatid',
                       @Rbid AS '@rbid',
                       0 AS '@ordrcode'
                   FOR XML PATH('Action')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XMessage, -- xml
               @xRet = @XMessage OUTPUT; -- xml
            
            SELECT @RsltCode = @XMessage.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)');
            IF(@RsltCode = '002')
            BEGIN
               -- بدست آوردن شماره درخواست اطلاع رسانی
               SELECT @TOrdrCode = @XMessage.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
               
               -- قراردادن شماره درخواست ارسال پیام تبلیغات درون درخواست اطلاع رسانی
               UPDATE dbo.[Order]
                  SET ORDR_CODE = @OrdrCode
                WHERE CODE = @TOrdrCode;
                
               INSERT INTO dbo.Order_Detail
               ( ORDR_CODE ,ELMN_TYPE ,ORDR_DESC, ORDR_CMNT, IMAG_PATH )
               SELECT TOP 1 @TOrdrCode, a.MESG_TYPE, 
                      N'⛔ عدم تایید درخواست ارسال پیام تبلیغات',
                      a.MESG_TEXT,
                      a.[FILE_ID]
                 FROM dbo.Service_Robot_Replay_Message a
                WHERE a.SRBT_ROBO_RBID = @Rbid
                  AND a.ORDT_ORDR_CODE = @OrdrCode -- شماره درخواست ارسال تبلیغات
                  AND a.CONF_STAT = '001'
                  AND a.HEDR_CODE = @Valu;               
            END
         END
         ELSE -- درخواست قبلا ردیف ارسال داشته و تایید نشده دوباره عدم تایید را ارسال میکنیم
         BEGIN
            INSERT INTO dbo.Order_Detail
            ( ORDR_CODE ,ELMN_TYPE ,ORDR_DESC, ORDR_CMNT, IMAG_PATH )
            SELECT TOP 1 @TOrdrCode, a.MESG_TYPE, 
                   N'⛔ عدم تایید درخواست ارسال پیام تبلیغات',
                   a.MESG_TEXT,
                   a.[FILE_ID]
              FROM dbo.Service_Robot_Replay_Message a
             WHERE a.SRBT_ROBO_RBID = @Rbid
               AND a.ORDT_ORDR_CODE = @OrdrCode -- شماره درخواست ارسال تبلیغات
               AND a.CONF_STAT = '001'
               AND a.HEDR_CODE = @Valu;               
         END 
         
         BEGIN/* آماده سازی ارسال پیام به مخاطبین */
	         DECLARE C$SndMsg10PJob CURSOR FOR
	            SELECT o.CODE, o.ORDR_TYPE
	              FROM dbo.[Order] o
	             WHERE o.ORDR_CODE = @OrdrCode
	               AND o.ORDR_STAT IN ( '001' )
	               AND o.ORDR_TYPE IN ('012' /* درخواست اطلاع رسانی ها */)
      	   
	         OPEN [C$SndMsg10PJob];
	         L$Loop_C$SndMsg10PJob:
	         FETCH [C$SndMsg10PJob] INTO @TOrdrCode, @TOrdrType;
      	   
	         IF @@FETCH_STATUS <> 0
	            GOTO L$EndLoop_C$SndMsg10PJob;
      	      
            UPDATE dbo.[Order]
               SET ORDR_STAT = '001'
             WHERE CODE = @TOrdrCode;
            
            SET @XMessage = (
               SELECT @Rbid AS '@rbid'
                     ,@UssdCode AS '@ussdcode'
                     ,@ChatID AS '@chatid'
                     ,'lesssndrdisaprvadv'  AS '@cmndtext'
                     ,@TOrdrCode AS '@ordrcode'
                     ,@Valu AS '@param'
                 FOR XML PATH('RequestInLineQuery')
            )
            EXEC dbo.CRET_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
            SET @XMessage = (
                SELECT 1 AS '@order',
                       @XMessage
                   FOR XML PATH('InlineKeyboardMarkup')
            );         
            
            -- ثبت منوی برای خروجی نهایی
            UPDATE dbo.Order_Detail
               SET INLN_KEYB_DNRM = @XMessage
             WHERE ORDR_CODE = @TOrdrCode
               AND SEND_STAT = '001';         
            
            SET @TDirPrjbCode = NULL;
            -- اگر درخواست نوع اعلام باشد باید به خوده مشتری مستقیما پیام داده شود
            IF @TOrdrType IN ( '012' )
            BEGIN
               SELECT @TDirPrjbCode = a.CODE
                 FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
                WHERE a.PRBT_ROBO_RBID = @Rbid
                  AND a.JOB_CODE = b.CODE
                  AND b.ORDR_TYPE = @TOrdrType
                  AND o.CODE = @TOrdrCode
                  AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
            END 
            
            SELECT  @XMessage = ( 
               SELECT @TOrdrCode AS '@code' ,
                      @Rbid AS '@roborbid' ,
                      @TOrdrType '@type',
                      @TDirPrjbCode '@dirprjbcode'
              FOR XML PATH('Order'), ROOT('Process')
            );
            EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            
            --UPDATE dbo.[Order]
            --   SET ORDR_STAT = '004'
            -- WHERE CODE = @TOrdrCode;
            
            GOTO L$Loop_C$SndMsg10PJob;
            L$EndLoop_C$SndMsg10PJob:
            CLOSE [C$SndMsg10PJob];
            DEALLOCATE [C$SndMsg10PJob];
	      END 
	   END 
	END 	
	COMMIT TRANSACTION [T$SEND_MEOJ_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   SET @XRet = (
          SELECT 'failed' AS '@rsltdesc',
                 '001' AS '@rsltcode',
                 @ErorMesg
             FOR XML PATH('Message'), ROOT('Result')
      );
      RAISERROR ( @ErorMesg, 16, 1 );
      ROLLBACK TRAN [T$SEND_MEOJ_P];
	END CATCH	
END
GO
