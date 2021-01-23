SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_S05C_P]
	@X XML, 
	@xRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$SAVE_S05C_P];
	
	DECLARE @OrdrCode BIGINT
	       ,@OrdrType VARCHAR(3)
	       ,@OrdrTypeNumb BIGINT
	       ,@Rbid BIGINT
	       ,@BaseUssdCode VARCHAR(250)
	       ,@TypeCode VARCHAR(3)
	       ,@ChatId BIGINT
	       ,@Input VARCHAR(100)
  	       ,@AmntTypeDesc NVARCHAR(20)
	       ,@AmntType VARCHAR(3)
	       ,@TaxPrct INT
	       ,@RbpdCode BIGINT
	       ,@offType VARCHAR(3)
	       ,@OffPrct REAL
	       ,@FreeShipInctAmnt BIGINT
	       ,@FreeShipOtctAmnt BIGINT
	       ,@OrdrExprStat VARCHAR(3)
	       ,@OrdrExprTime INT
	       ,@SaleCartNumbDnrm REAL
	       ,@IsLoopOprt VARCHAR(3)
	       ,@GiftTarfCode VARCHAR(100)
	       ,@SrspCode BIGINT
	       ,@MinOrdr REAL
	       ,@CrntNumb REAL;

   -- بدست آوردن آیین نامه فعال برای بدست آوردن ارزش افزوده
   SELECT @TaxPrct = ISNULL(TAX_PRCT, 0) + ISNULL(DUTY_PRCT, 0),
          @AmntTypeDesc = a.DOMN_DESC,
          @AmntType = AMNT_TYPE
     FROM iScsc.dbo.Regulation, iScsc.dbo.[D$ATYP] a
    WHERE REGL_STAT = '002'
      AND [TYPE] = '001'
      AND AMNT_TYPE = a.VALU;            
	
	-- در این قسمت اندازه کد تعرفه ورودی را زیاد گرفتیم بخاطر اینکه ممکن است کاربر ورودی های مختلفی داشته باشد
	-- مثلا
	-- 00701005                   => مسیر بهشت خسرو محمودیان روز های زوج شنبه تا چهارشنبه ساعت 14:00 تا 16:00 سه ماه 36 جلسه مبلغ 360 هزار تومن به تاریه امروز مباشد
	-- 00701005*d12               => این به معنای همان عبارت بالا ولی برای 12 روز آینده 
	-- 00701005*dt1398/12/20      => این به معنای این می باشد که تاریخ شروع دوره در تاریخ 1398/12/20 شروع میشود
	-- 00701005*n2                => دو دوره پشت سرهم ثبت نام شود
	-- 00701005*++                => این گزینه برای اضافه کردن خودکار میباشد
	-- 00701005*--                => این گزینه برای کم کردن خودکار میباشد
	-- 00701005*+=5               => اضافه کردن تعداد 5 عدد به کالای مورد نظر
	-- 00701055*-=5               => کم کردن تعداد 5 عدد از کالای مورد نظر
	-- 00701005*n2*d12            =>
	-- 00701005*n2*dt1398/12/20   =>
	-- 00701005*del               => حذف کردن دوره از لیست تمدید
	-- 00701055*count             => تعداد کالای ثبت شده درون فاکتور
	-- show                       => نمایش سبد خرید دوره جاری
	-- empty                      => حذف تمامی آیتم های سبد خرید دوره
	
	SELECT @OrdrCode = @X.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT')
	      ,@BaseUssdCode = @X.query('//Action').value('(Action/@ussdcode)[1]', 'VARCHAR(250)')
	      ,@Rbid = @X.query('//Action').value('(Action/@rbid)[1]', 'BIGINT')
	      --,@TypeCode = @X.query('//Order').value('(Order/@typecode)[1]', 'VARCHAR(3)')
	      ,@ChatId   = @X.query('//Action').value('(Action/@chatid)[1]', 'BIGINT')
	      ,@Input = REPLACE(LOWER(@X.query('//Action').value('(Action/@input)[1]', 'VARCHAR(100)')), ' ', '')
	      ,@IsLoopOprt = @X.query('//Action').value('(Action/@isloopoprt)[1]', 'VARCHAR(3)');
	
	-- بدست آوردن اطلاعات از جدول ربات
	SELECT @FreeShipInctAmnt = ISNULL(FREE_SHIP_INCT_AMNT, 0),
	       @FreeShipOtctAmnt = ISNULL(FREE_SHIP_OTCT_AMNT, 0),
	       @OrdrExprStat = ISNULL(ORDR_EXPR_STAT, '000'),
	       @OrdrExprTime = ISNULL(ORDR_EXPR_TIME, 15)
	  FROM dbo.Robot
	 WHERE RBID = @Rbid;
	
	-- مشخص شدن نوع درخواست ارسال شده
	SELECT @OrdrType = o.ORDR_TYPE,
	       @OrdrTypeNumb = o.ORDR_TYPE_NUMB
	  FROM dbo.[Order] o
	 WHERE o.CODE = @OrdrCode;

	-- 1399/10/26 * بررسی اینکه آیا فروشنده اعتبار دارد یا خیر
	-- ابتدا فروشنده را پیدا میکنیم و بررسی میکنیم که آیا اعتبار دارد یا خیر
	IF @OrdrType IN ( '004' ) AND NOT EXISTS(
	   SELECT *
	     FROM dbo.Service_Robot sr, dbo.Wallet w, dbo.Service_Robot_Group g
	    WHERE sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
	      AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
	      AND sr.SERV_FILE_NO = g.SRBT_SERV_FILE_NO
	      AND sr.ROBO_RBID = g.SRBT_ROBO_RBID
	      AND g.GROP_GPID = 131
	      AND g.STAT = '002'
	      AND w.WLET_TYPE = '001' -- کیف پول اعتباری
	      AND w.AMNT_DNRM > 0
	)
	BEGIN
	   -- Call Send_Meoj_P for Alert to Admin Shop to charge shop
	   SET @xRet =
      (
         SELECT @Rbid AS '@rbid',
                @ChatID AS 'Order/@chatid',
                '012' AS 'Order/@type',
                'shopnocrdtwlet' AS 'Order/@oprt'
            FOR XML PATH('Robot')
      );
      EXEC dbo.SEND_MEOJ_P @X = @xRet, @XRet = @xRet OUTPUT;
	   -- Goto End Procedure And Show Can not save Order For Service
	   SET @TypeCode = '012';
	   GOTO L$ShowMessage;
	END 
	 
	
	-- حال استخراج داده های کد تعرفه
	DECLARE @tarfcode VARCHAR(100) = null
	       ,@d INT = 0
	       ,@dt DATE = NULL
	       ,@n REAL = 1
	       ,@del BIT = 0
	       ,@count BIT = 0
	       ,@incn BIT = 0
	       ,@decn BIT = 0	       	       
	       ,@inc BIT = 0
	       ,@dec BIT = 0;
	
	DECLARE @Index INT = 0
	       ,@Item VARCHAR(50)
	       ,@xTemp XML;
   
   -- اگر مشتری درخواست نمایش ثبت خرید خود را داده باشد
   IF @Input = 'show'
   BEGIN
      -- نمایش اطلاعات سبد خرید
      SET @TypeCode = '004'
      GOTO L$ShowResult;
   END 
   ELSE IF @Input = 'show_invoice_payment'
   BEGIN
      SET @TypeCode = '006';
      GOTO L$ShowResult;
   END 
   ELSE IF @Input = 'show_shipping'
   BEGIN
      SET @TypeCode = '008'
      GOTO L$ShowResult;
   END 
   ELSE IF @Input = 'empty'
   BEGIN
      -- در درون فاکتور رسید پرداخت توسط فروشگاه تایید شده باشد فاکتور به هیچ عنوان قابل ویرایش نیست و مشتری موظف به پرداخت کل فاکتور و پایانی کردن سفارش می باشد
      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '005' AND os.CONF_STAT = '002')
      BEGIN
         SET @xRet = (
             SELECT 'successful' AS '@rsltdesc',
                    '002' AS '@rsltcode',
                    @OrdrCode AS '@ordrcode',
                    N'فاکتور دارای رسید پرداخت تایید شده توسط فروشنده می باشد، شما نمی توانید تغییراتی درون فاکتور ایجاد کنید، لطفا فاکتور خود را پایانی کنید'
                FOR XML PATH('Message'), ROOT('Result')
         );
         
         GOTO L$End;
      END 
      
      -- تنظیم اولیه برای نحوه ارسال بسته سفارش
      UPDATE dbo.[Order]
         SET HOW_SHIP = '000',
             STRT_DATE = GETDATE()
       WHERE CODE = @OrdrCode;
      
      SELECT *
        INTO T#Order_Detail
        FROM dbo.Order_Detail
       WHERE ORDR_CODE = @OrdrCode;      
      
      -- حذف تمامی آیتم های دوره ثبت شده
      DELETE dbo.Order_Detail
       WHERE ORDR_CODE = @OrdrCode;     
      
      -- 1399/04/19
      -- بروزرسانی موجودی جدول کالاها	
      -- بارشگت محصول به قفسه کالا
      UPDATE p
         SET p.CRNT_NUMB_DNRM = WREH_INVR_NUMB - (SALE_NUMB_DNRM + (p.SALE_CART_NUMB_DNRM - od.NUMB))
             --p.SALE_CART_NUMB_DNRM += @n
        FROM dbo.Service_Robot_Seller_Product p, T#Order_Detail od
       WHERE od.ORDR_CODE = @OrdrCode
         AND od.TARF_CODE = p.TARF_CODE
         AND p.PROD_TYPE = '002';
      
      DROP TABLE T#Order_Detail;      
      
      -- برگشت مبلغ به کارت اعتباری مشتری
      UPDATE g 
         SET g.TEMP_AMNT_USE = 0
        FROM dbo.Service_Robot_Gift_Card g, dbo.Order_State os
       WHERE g.GCID = os.GIFC_GCID
         AND os.ORDR_CODE = @OrdrCode;
      
      -- برگشت مبلغ کسر شده از کیف پول
      UPDATE w
         SET w.TEMP_AMNT_USE = 0
        FROM dbo.Wallet w, dbo.Wallet_Detail wd
       WHERE w.CODE = wd.WLET_CODE
         AND wd.ORDR_CODE = @OrdrCode;
       
      -- هر گونه ردیف در مورد تخفیف / واریزی / رسید پرداخت تایید نشده را حذف میکنیم
      DELETE dbo.Order_State
       WHERE ORDR_CODE = @OrdrCode
         AND AMNT_TYPE NOT IN ('005' /* رسید های پرداخت نیاز به پاک شدن ندارند */);
 
      DELETE dbo.Wallet_Detail
       WHERE ORDR_CODE = @OrdrCode
         AND CONF_STAT = '003';      
      
      -- اگر کالاهایی که در قسمت تخفیف عادی لحاظ شده اند و با کارت تخفیف تغییرات قیمت داشته باشند باید دوباره به قیمت اولیه فروشگاه برگردند
      UPDATE od
         SET od.OFF_PRCT = 0,
             od.OFF_TYPE = NULL,
             od.OFF_KIND = NULL
        FROM dbo.Order_Detail od
       WHERE od.ORDR_CODE = @OrdrCode
         AND NOT EXISTS(
             SELECT *
               FROM dbo.Robot_Product_Discount d
              WHERE od.TARF_CODE = d.TARF_CODE
                AND d.ACTV_TYPE = '002'
                AND (
                      ( d.OFF_TYPE = '001' /* showprodofftimer */ AND d.REMN_TIME >= GETDATE() ) OR 
                        d.OFF_TYPE != '001'
                )
       );
      
      IF @OrdrType = '004' 
         SET @TypeCode = ''
      ELSE IF @OrdrType = '013'
         SET @TypeCode = '011'
      ELSE IF @OrdrType = '015'
         SET @TypeCode = '010'
       
      GOTO L$ShowResult;
   END 
   ELSE IF @Input IN ( 'final', 'history' )
   BEGIN
      -- ابتدا بررسی میکنیم که آیا فاکتور قبلا ذخیره شده یا خیر
      IF NOT EXISTS(SELECT * FROM dbo.Order_Step_History WHERE ORDR_CODE = @OrdrCode AND ORDR_STAT = '004' /* سفارش پایانی و پرداخت شده */)
      BEGIN
         SET @xRet = (
             SELECT @OrdrCode AS '@ordrcode'
                FOR XML PATH('Payment')
         );
         
         EXEC dbo.SAVE_PYMT_P @X = @xRet, -- xml
             @xRet = @xRet OUTPUT -- xml         
      END 
      
      SET @TypeCode = '009' -- Show Final Order
      GOTO L$ShowResult;
   END 
   ELSE IF @Input = 'howinccashwlet' -- افزایش مبلغ کیف پول نقدینگی
   BEGIN
      SET @TypeCode = '010';
      GOTO L$ShowResult;
   END
   ELSE IF @Input = 'howinccreditwlet' -- افزایش مبلغ کیف پول اعتباری
   BEGIN
      SET @TypeCode = '011';
      GOTO L$ShowResult;
   END
   -- در این قسمت میخواهیم گزینه ای اضافه کنیم که اگر مشتری بخواهد اطلاعات بیشتری را وارد کند 
   -- که با کاما از هم جدا میشوند را ارسال کنند
   
   DECLARE @FrstStepCmnd NVARCHAR(100) = @Input;
   L$Loop$NextItem:
   SELECT TOP 1 @Input = Item FROM dbo.SplitString(@FrstStepCmnd, ',');   
   SELECT @FrstStepCmnd = SUBSTRING(REPLACE(@FrstStepCmnd, @Input, ''), 2, LEN(@FrstStepCmnd) - 1);
   
   DECLARE C$Items CURSOR FOR
      SELECT Item FROM dbo.SplitString(@Input, '*');
   SET @Index = 0;
   OPEN [C$Items];
   L$FetchC$Item_DATA1:
   FETCH NEXT FROM [C$Items] INTO @Item;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndC$Item_DATA1;
   
   IF @Index = 0
      SET @tarfcode = @Item;
   ELSE IF @Index = 1
   BEGIN
      -- n2, d12, dt1398/12/20, del
      IF SUBSTRING(@Item,1,1) = 'n'
         SET @n = CAST( SUBSTRING(@Item, 2, LEN(@Item)) AS REAL );
      ELSE IF SUBSTRING(@Item,1,2) = 'dt'
         SET @dt = dbo.GET_STOM_U(SUBSTRING(@Item, 3, LEN(@Item)));
      ELSE IF SUBSTRING(@Item,1,3) = 'del'
         SET @del = 1;
      ELSE IF SUBSTRING(@Item,1,5) = 'count'
         SET @count = 1;
      ELSE IF SUBSTRING(@Item,1,1) = 'd'
         SET @d = CAST( SUBSTRING(@Item, 2, LEN(@Item)) AS int );      
      ELSE IF SUBSTRING(@Item,1,2) = '++'
         SET @inc = 1;
      ELSE IF SUBSTRING(@Item,1,2) = '+='
      BEGIN 
         SET @incn = 1;
         SET @n = CAST( SUBSTRING(@Item, 3, LEN(@Item)) AS REAL );
      END 
      ELSE IF SUBSTRING(@Item,1,2) = '--'
         SET @dec = 1;
      ELSE IF SUBSTRING(@Item,1,2) = '-='
      BEGIN
         SET @decn = 1;
         SET @n = CAST( SUBSTRING(@Item, 3, LEN(@Item)) AS REAL );
      END 
   END
   ELSE IF @Index = 2
   BEGIN
      -- n2, d12, dt1398/12/20, del
      IF SUBSTRING(@Item,1,1) = 'n'
         SET @n = CAST( SUBSTRING(@Item, 2, LEN(@Item)) AS REAL );
      ELSE IF SUBSTRING(@Item,1,2) = 'dt'
         SET @dt = dbo.GET_STOM_U(SUBSTRING(@Item, 3, LEN(@Item)));
      ELSE IF SUBSTRING(@Item,1,3) = 'del'
         SET @del = 1;
      ELSE IF SUBSTRING(@Item,1,5) = 'count'
         SET @count = 1;         
      ELSE IF SUBSTRING(@Item,1,1) = 'd'
         SET @d = CAST( SUBSTRING(@Item, 2, LEN(@Item)) AS int );
      ELSE IF SUBSTRING(@Item,1,2) = '++'
         SET @inc = 1;
      ELSE IF SUBSTRING(@Item,1,2) = '+='
      BEGIN 
         SET @incn = 1;
         SET @n = CAST( SUBSTRING(@Item, 3, LEN(@Item)) AS REAL );
      END 
      ELSE IF SUBSTRING(@Item,1,2) = '--'
         SET @dec = 1;
      ELSE IF SUBSTRING(@Item,1,2) = '-='
      BEGIN
         SET @decn = 1;
         SET @n = CAST( SUBSTRING(@Item, 3, LEN(@Item)) AS REAL );
      END 
   END 
   
   SET @Index += 1;
   GOTO L$FetchC$Item_DATA1;
   L$EndC$Item_DATA1:
   CLOSE [C$Items];
   DEALLOCATE [C$Items];       
	
	-- اگر تعرفه درون سیستم وجود نداشته باشد
	--IF NOT EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode)
	--BEGIN
	--   SET @xRet = (
 --         SELECT 'failed' AS '@rsltdesc',
 --                '001' AS '@rsltcode',
 --                @OrdrCode AS '@ordrcode',
 --                N'⚠️ کد وارد شده وجود ندارد، لطفا از گزینه *جستجو* و با *وارد کردن نام محصول* می توانید  کد محصولات را مشاهده کنید'
 --            FOR XML PATH('Message'), ROOT('Result')
 --     );
      
 --     GOTO L$End;
	--END 
	
	-- متغیر های محلی برای جدول ردیف درخواست
	DECLARE @OrdrDesc NVARCHAR(MAX) /* شرح دوره ثبت شده */
	       ,@OrdrCmnt NVARCHAR(4000) /* عنوان ثبت دوره */
	       ,@ExpnPric BIGINT
	       ,@ExtrPrct BIGINT
	       ,@BuyPric BIGINT
	       ,@PrftPric BIGINT	       
	       ,@TarfDate DATE
	       ,@RqtpCode VARCHAR(3);
	
	-- بررسی اینکه متوجه شویم کد تعرفه وارد شده درآمد متفرقه هست یا تمدید دوره یا ثبت نام       
   IF EXISTS(
       SELECT  N'📔  *' + e.EXPN_DESC + N'* ' + CHAR(10) + N'👈 [ کد ] *' + ISNULL(CAST(e.ORDR_ITEM AS NVARCHAR(100)), ' --- ') + N'* [ مبلغ ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, e.PRIC + ISNULL(e.EXTR_PRCT, 0)), 1), '.00', '') + N'* [ ' + @AmntTypeDesc + N' ] ' + CHAR(10) + CHAR(10)
         FROM iScsc.dbo.Expense e, iScsc.dbo.Expense_Type et, iScsc.dbo.Request_Requester rr
        WHERE e.EXTP_CODE = et.CODE
          AND et.RQRQ_CODE = rr.CODE
          AND rr.RQTP_CODE = '016'
          AND rr.RQTT_CODE = '001' 
          AND e.EXPN_STAT = '002'
          AND CAST(e.ORDR_ITEM AS VARCHAR(MAX)) = @tarfcode
   )
   BEGIN
      SET @RqtpCode = '016'
   END 
   ELSE
   BEGIN
      -- بررسی اینکه متوجه شویم درخواست ثبت عضویت جدید میباشد یا تمدید دوره
      --  بهترین روش این هست که بررسی کنیم که با این کد وارد شده قبلا کسی ثبت شده یا خیر
      -- اگر کد موجود باشد عملیات تمدید را انجام میدیم ولی اگر ناموجود باشد عملیات ثبت نام
      IF EXISTS(SELECT * FROM iScsc.dbo.Fighter f WHERE f.CHAT_ID_DNRM = @ChatId)      
         SET @RqtpCode = CASE @OrdrType WHEN '004' then '009' WHEN '015' THEN '020' END
      ELSE 
         SET @RqtpCode = CASE @OrdrType WHEN '004' THEN '001' WHEN '015' THEN '020' END 
   END
	
	L$DeleteTarfCode:
	-- حال در این قسمت مشخص میکنیم که مشتری چه درخواستی داشته است
	IF @del = 1
	BEGIN
	   -- در درون فاکتور رسید پرداخت توسط فروشگاه تایید شده باشد فاکتور به هیچ عنوان قابل ویرایش نیست و مشتری موظف به پرداخت کل فاکتور و پایانی کردن سفارش می باشد
      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '005' AND os.CONF_STAT = '002')
      BEGIN
         SET @xRet = (
             SELECT 'successful' AS '@rsltdesc',
                    '002' AS '@rsltcode',
                    @OrdrCode AS '@ordrcode',
                    N'فاکتور دارای رسید پرداخت تایید شده توسط فروشنده می باشد، شما نمی توانید تغییراتی درون فاکتور ایجاد کنید، لطفا فاکتور خود را پایانی کنید'
                FOR XML PATH('Message'), ROOT('Result')
         );
         
         GOTO L$End;
      END 
      
      -- 1399/04/19
      -- بروزرسانی موجودی جدول کالاها	
      -- بازگشت محصول به قفسه کالا
      IF EXISTS (SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */)
      BEGIN
         SELECT *
           INTO T#Order_Detail
           FROM dbo.Order_Detail
          WHERE ORDR_CODE = @OrdrCode
            AND TARF_CODE = @tarfcode;
         
         -- حذف تمامی آیتم های دوره ثبت شده
         DELETE dbo.Order_Detail
          WHERE ORDR_CODE = @OrdrCode
            AND TARF_CODE = @tarfcode;
          
         SELECT @n = od.NUMB
           FROM T#Order_Detail od
          WHERE od.ORDR_CODE = @OrdrCode
            AND od.TARF_CODE = @tarfcode;
            
         --UPDATE p
         --   SET p.CRNT_NUMB_DNRM = WREH_INVR_NUMB - (SALE_NUMB_DNRM + (SALE_CART_NUMB_DNRM - @n))
         --  FROM dbo.Service_Robot_Seller_Product p
         -- WHERE p.TARF_CODE = @tarfcode;
         
         -- 1399/04/19
         -- بروزرسانی موجودی جدول کالاها	
         -- بارشگت محصول به قفسه کالا
         UPDATE p
            SET p.CRNT_NUMB_DNRM = WREH_INVR_NUMB - (SALE_NUMB_DNRM + (p.SALE_CART_NUMB_DNRM - od.NUMB))
           FROM dbo.Service_Robot_Seller_Product p, T#Order_Detail od
          WHERE od.ORDR_CODE = @OrdrCode
            AND od.TARF_CODE = p.TARF_CODE
            AND p.PROD_TYPE = '002';

         -- 1399/05/02
         -- بررسی اینکه آیا کالای مورد نظر دارای کالای هدیه بوده یا خیر
         --UPDATE pgt 
         --   SET pgt.CRNT_NUMB_DNRM = pgt.WREH_INVR_NUMB - (pgt.SALE_NUMB_DNRM + (pgt.SALE_CART_NUMB_DNRM - @n)) -- بازگشت کالاهای هدیه به قفسه خرید
         --  FROM T#Order_Detail od, dbo.Service_Robot_Seller_Product p, dbo.Service_Robot_Seller_Product_Gift pg, dbo.Order_Detail god, dbo.Service_Robot_Seller_Product pgt
         -- WHERE p.TARF_CODE = @tarfcode
         --   AND p.CODE = pg.SRSP_CODE
         --   AND pg.GIFT_TARF_CODE_DNRM = god.TARF_CODE
         --   AND god.ORDR_CODE = @OrdrCode
         --   AND god.TARF_CODE = pgt.TARF_CODE
         --   AND pgt.CODE = pg.SSPG_CODE;
         
         DROP TABLE T#Order_Detail;
         
         DECLARE C$DelGiftProds1 CURSOR FOR
            SELECT pgt.TARF_CODE, god.NUMB
              FROM dbo.Service_Robot_Seller_Product p, dbo.Service_Robot_Seller_Product_Gift pg, dbo.Order_Detail god, dbo.Service_Robot_Seller_Product pgt
             WHERE p.TARF_CODE = @tarfcode
               AND p.CODE = pg.SRSP_CODE
               AND pg.GIFT_TARF_CODE_DNRM = god.TARF_CODE
               AND god.ORDR_CODE = @OrdrCode
               AND god.TARF_CODE = pgt.TARF_CODE
               AND pgt.CODE = pg.SSPG_CODE;
         
         OPEN [C$DelGiftProds1];
         L$DelGiftProds1:
         FETCH [C$DelGiftProds1] INTO @GiftTarfCode, @count;
         
         IF @@FETCH_STATUS <> 0
            GOTO L$EndDelGiftProds1;
         
         UPDATE dbo.Order_Detail
            SET NUMB -= @n
          WHERE ORDR_CODE = @OrdrCode
            AND TARF_CODE = @GiftTarfCode
            AND NUMB >= @n;
         
         SELECT *
           INTO T#Order_Detail
           FROM dbo.Order_Detail
          WHERE ORDR_CODE = @OrdrCode
            AND TARF_CODE = @GiftTarfCode;
         
         DELETE dbo.Order_Detail
          WHERE ORDR_CODE = @OrdrCode
            AND TARF_CODE = @GiftTarfCode
            AND NUMB = 0;
         
         -- 1399/05/03
         IF EXISTS(SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @GiftTarfCode)
         BEGIN            
            UPDATE p
               SET p.SALE_CART_NUMB_DNRM = 0
              FROM dbo.Service_Robot_Seller_Product p, T#Order_Detail od
             WHERE od.ORDR_CODE = @OrdrCode
               AND od.TARF_CODE = p.TARF_CODE
               AND p.PROD_TYPE = '002';
         END
         
         -- 1399/04/19
         -- بروزرسانی موجودی جدول کالاها	
         -- بازگشت محصول به قفسه کالا
         UPDATE p
            SET p.CRNT_NUMB_DNRM = p.WREH_INVR_NUMB - (p.SALE_NUMB_DNRM + (p.SALE_CART_NUMB_DNRM /*- od.NUMB*/))
           FROM dbo.Service_Robot_Seller_Product p, T#Order_Detail od
          WHERE od.ORDR_CODE = @OrdrCode
            AND od.TARF_CODE = p.TARF_CODE
            AND p.PROD_TYPE = '002';
         
         DROP TABLE T#Order_Detail;
            
         GOTO L$DelGiftProds1;
         L$EndDelGiftProds1:
         CLOSE [C$DelGiftProds1];
         DEALLOCATE [C$DelGiftProds1];
          
         SET @n = 0;
         SET @count = 0;
      END 
      
	   -- در این قسمت فقط ردیف کد تعرفه را از ردیف درخواست حذف میکنیم
	   DELETE dbo.Order_Detail
	    WHERE ORDR_CODE = @OrdrCode
	      AND TARF_CODE = @tarfcode;
	   
	   -- برگشت مبلغ به کارت اعتباری مشتری
      UPDATE g 
         SET g.TEMP_AMNT_USE = 0
        FROM dbo.Service_Robot_Gift_Card g, dbo.Order_State os
       WHERE g.GCID = os.GIFC_GCID
         AND os.ORDR_CODE = @OrdrCode;
      
      -- برگشت مبلغ کسر شده از کیف پول
      UPDATE w
         SET w.TEMP_AMNT_USE = 0
        FROM dbo.Wallet w, dbo.Wallet_Detail wd
       WHERE w.CODE = wd.WLET_CODE
         AND wd.ORDR_CODE = @OrdrCode;
      
      -- هر گونه ردیف در مورد تخفیف / واریزی / رسید پرداخت تایید نشده را حذف میکنیم
      DELETE dbo.Order_State
       WHERE ORDR_CODE = @OrdrCode
         AND AMNT_TYPE NOT IN ('005' /* رسید های پرداخت نیاز به پاک شدن ندارند */); 
       
      DELETE dbo.Wallet_Detail
       WHERE ORDR_CODE = @OrdrCode
         AND CONF_STAT = '003';      
	   
	   -- اگر کالاهایی که در قسمت تخفیف عادی لحاظ شده اند و با کارت تخفیف تغییرات قیمت داشته باشند باید دوباره به قیمت اولیه فروشگاه برگردند
      UPDATE od
         SET od.OFF_PRCT = 0,
             od.OFF_TYPE = NULL,
             od.OFF_KIND = NULL
        FROM dbo.Order_Detail od
       WHERE od.ORDR_CODE = @OrdrCode
         AND NOT EXISTS(
             SELECT *
               FROM dbo.Robot_Product_Discount d
              WHERE od.TARF_CODE = d.TARF_CODE
                AND d.ACTV_TYPE = '002'
                AND (
                      ( d.OFF_TYPE = '001' /* showprodofftimer */ AND d.REMN_TIME >= GETDATE() ) OR 
                        d.OFF_TYPE != '001'
                )
       );
	   
	   -- حذف ردیف تعرفه
	   SET @TypeCode = '002';
	   GOTO L$ShowResult;
	END
	IF @count = 1
	BEGIN
	   -- بررسی تعداد کالای مورد نظر در فاکتور
	   -- پیدا کردن تعداد کالا مورد نظر 
	   SET @TypeCode = '007';
	   GOTO L$ShowResult;
	END  
	ELSE 
	BEGIN
	   IF @OrdrType = '004' /* درخواست ثبت سفارش */ AND 
	      NOT EXISTS(
	      SELECT @tarfcode
	        FROM iScsc.dbo.Method m, iScsc.dbo.Category_Belt cb, iScsc.dbo.Club_Method cm, iScsc.dbo.Fighter f, iScsc.dbo.[D$SXTP] s, iScsc.dbo.[D$DYTP] d
          WHERE m.CODE = cb.MTOD_CODE
            AND m.CODE = cm.MTOD_CODE
            AND cm.COCH_FILE_NO = f.FILE_NO
            AND cm.SEX_TYPE = s.VALU
            AND cm.DAY_TYPE = d.VALU
            AND m.NATL_CODE + cb.NATL_CODE + cm.NATL_CODE = @tarfcode
            AND m.MTOD_STAT = '002'
            AND cm.MTOD_STAT = '002'
            AND f.ACTV_TAG_DNRM >= '101'
	   ) AND 
	   NOT EXISTS(
	       SELECT *
            FROM iScsc.dbo.Expense e, iScsc.dbo.Expense_Type et, iScsc.dbo.Request_Requester rr
           WHERE e.EXTP_CODE = et.CODE
             AND et.RQRQ_CODE = rr.CODE
             AND rr.RQTP_CODE = '016'
             AND rr.RQTT_CODE = '001' 
             AND e.EXPN_STAT = '002'
             AND CAST(e.ORDR_ITEM AS NVARCHAR(MAX)) = @tarfcode
	   )
	   BEGIN
	      SELECT @xRet = (
	         SELECT N'⚠️ کد تعرفه وارد شده صحیح نمیباشد'
	        FOR XML PATH('Message'), ROOT('Result')	     
	      );
	      
	      GOTO L$End;
	   END 
	   -- در این قسمت مشتری میخواهد که اطلاعات دوره برای خود ثبت کند
	   -- آیا مشتری قبلا این تعرفه را وارد کرده است یا خیر
	   ELSE IF @OrdrType = '004' /* درخواست ثبت سفارش */ AND 
	        EXISTS(
	         SELECT *
	           FROM dbo.Order_Detail od
	          WHERE od.ORDR_CODE = @OrdrCode
	            AND od.TARF_CODE = @tarfcode
	        )
	   BEGIN
         -- محاسبه زمان انجام عملیات تعرفه   
         IF(@d != 0)
            SET @TarfDate = DATEADD(DAY, @d, GETDATE());
         ELSE IF @dt IS NOT NULL
            SET @TarfDate = @dt;         
         ELSE
            SELECT @TarfDate = TARF_DATE
              FROM dbo.Order_Detail
             WHERE ORDR_CODE = @OrdrCode
               AND TARF_CODE = @tarfcode;   
	      
	      IF @RqtpCode IN ( '001' , '009' )
	      BEGIN
	         -- اگر کد تعرفه جدید باشد
	         SELECT @OrdrCmnt = N'👈 ثبت دوره غیرحضوری',
	                @OrdrDesc = 
	                  CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'👱 ' WHEN '002' THEN N'👩 ' END + 
	                  N'*'+ f.NAME_DNRM + N'* ' +
	                  N'📔 *'+ m.MTOD_DESC + N'* ' +
	                  N'📦 *' + cb.CTGY_DESC + N'* ' +
	                  CASE s.VALU WHEN '001' THEN N' 👬 ' WHEN '002' THEN N' 👭 ' WHEN '003' THEN N' 👫 ' END +
	                  N'[ *' + s.DOMN_DESC + N'* ] ☀️ [ *' + d.DOMN_DESC + N'* ] [ *' +  CAST(cm.STRT_TIME AS VARCHAR(5)) + N'* ] - [ *' + CAST(cm.END_TIME AS VARCHAR(5)) + N'* ]' + 
	                  (
	                     SELECT N'[ *' + d.DOMN_DESC + N'* ] ,'
	                       FROM iScsc.dbo.Club_Method_Weekday cmw, iScsc.dbo.[D$WKDY] d
	                      WHERE cmw.CBMT_CODE = cm.CODE
	                        AND cmw.WEEK_DAY = d.VALU
	                        AND cmw.STAT = '002'
	                        ORDER BY d.VALU
	                        FOR XML PATH('')	                    
	                  ) + CHAR(10) + 
	                  N'📆 [ *شروع دوره* ] *' + iRoboTech.dbo.GET_MTOS_U(@TarfDate) + N'*',
	                  @ExpnPric = cb.PRIC
              FROM iScsc.dbo.Method m, iScsc.dbo.Category_Belt cb, iScsc.dbo.Club_Method cm, iScsc.dbo.Fighter f, iScsc.dbo.[D$SXTP] s, iScsc.dbo.[D$DYTP] d
             WHERE m.CODE = cb.MTOD_CODE
               AND m.CODE = cm.MTOD_CODE
               AND cm.COCH_FILE_NO = f.FILE_NO
               AND cm.SEX_TYPE = s.VALU
               AND cm.DAY_TYPE = d.VALU
               AND m.NATL_CODE + cb.NATL_CODE + cm.NATL_CODE = @tarfcode
               AND m.MTOD_STAT = '002'
               AND cm.MTOD_STAT = '002'
               AND f.ACTV_TAG_DNRM >= '101';
         END
         ELSE IF @RqtpCode = '016'
         BEGIN
            SELECT @ExpnPric = e.PRIC,
                   @OrdrCmnt = CAST(e.ORDR_ITEM AS VARCHAR(4000)),
                   @OrdrDesc = e.EXPN_DESC
              FROM iScsc.dbo.Expense e, iScsc.dbo.Expense_Type et, iScsc.dbo.Request_Requester rr
             WHERE e.EXTP_CODE = et.CODE
               AND et.RQRQ_CODE = rr.CODE
               AND rr.RQTP_CODE = '016'
               AND rr.RQTT_CODE = '001' 
               AND e.EXPN_STAT = '002'   
               AND CAST(e.ORDR_ITEM AS VARCHAR(MAX)) = @tarfcode
         END
         
         SET @ExtrPrct = @ExpnPric * @TaxPrct / 100;
            
	      -- مشتری این تعرفه را قبلا وارد کرده است
	      -- در این قسمت اطلاعات را باید بروزرسانی شود
	      -- tarfcode, n(++|--|+=x|-=x), d, dt
	      IF @inc = 1
	         SELECT @n = NUMB + 1
	           FROM dbo.Order_Detail
	          WHERE ORDR_CODE = @OrdrCode
	            AND TARF_CODE = @tarfcode;
	      ELSE IF @dec = 1
	         SELECT @n = NUMB - 1
	           FROM dbo.Order_Detail
	          WHERE ORDR_CODE = @OrdrCode
	            AND TARF_CODE = @tarfcode;
	      ELSE IF @incn = 1
	         SELECT @n = NUMB + @n
	           FROM dbo.Order_Detail
	          WHERE ORDR_CODE = @OrdrCode
	            AND TARF_CODE = @tarfcode;
	      ELSE IF @decn = 1
	         SELECT @n = NUMB - @n
	           FROM dbo.Order_Detail
	          WHERE ORDR_CODE = @OrdrCode
	            AND TARF_CODE = @tarfcode;
	      
	      -- اگر هزینه درون ربات با تخفیف قرار گرفته شده باشد	      
         SELECT TOP 1 @RbpdCode = rpd.CODE, @OffPrct = rpd.OFF_PRCT, @offType = rpd.OFF_TYPE
           FROM dbo.Robot_Product_Discount rpd
          WHERE rpd.ROBO_RBID = @Rbid
            AND rpd.TARF_CODE = @tarfcode
            AND rpd.ACTV_TYPE = '002' --  فعال باشد
          ORDER BY rpd.OFF_TYPE;
         
         -- در درون فاکتور رسید پرداخت توسط فروشگاه تایید شده باشد فاکتور به هیچ عنوان قابل ویرایش نیست و مشتری موظف به پرداخت کل فاکتور و پایانی کردن سفارش می باشد
         IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '005' AND os.CONF_STAT = '002')
         BEGIN
            SET @xRet = (
                SELECT 'successful' AS '@rsltdesc',
                       '002' AS '@rsltcode',
                       @OrdrCode AS '@ordrcode',
                       N'فاکتور دارای رسید پرداخت تایید شده توسط فروشنده می باشد، شما نمی توانید تغییراتی درون فاکتور ایجاد کنید، لطفا فاکتور خود را پایانی کنید'
                   FOR XML PATH('Message'), ROOT('Result')
            );
            
            GOTO L$End;
         END
         
         -- برگشت مبلغ به کارت اعتباری مشتری
         UPDATE g 
            SET g.TEMP_AMNT_USE = 0
           FROM dbo.Service_Robot_Gift_Card g, dbo.Order_State os
          WHERE g.GCID = os.GIFC_GCID
            AND os.ORDR_CODE = @OrdrCode;
         
         -- برگشت مبلغ کسر شده از کیف پول
         UPDATE w
            SET w.TEMP_AMNT_USE = 0
           FROM dbo.Wallet w, dbo.Wallet_Detail wd
          WHERE w.CODE = wd.WLET_CODE
            AND wd.ORDR_CODE = @OrdrCode;
          
         -- اگر اطلاعات فاکتور عوض شود در صورتی که کد تخفیف ثبت کرده باشیم باید کد تخفیف را حذف کنیم
         -- هر گونه ردیف در مورد تخفیف / واریزی / رسید پرداخت تایید نشده را حذف میکنیم
         DELETE dbo.Order_State
          WHERE ORDR_CODE = @OrdrCode
            AND AMNT_TYPE NOT IN ('005' /* رسید های پرداخت نیاز به پاک شدن ندارند */);
         
         DELETE dbo.Wallet_Detail
          WHERE ORDR_CODE = @OrdrCode
            AND CONF_STAT = '003';
         
         -- اگر کالاهایی که در قسمت تخفیف عادی لحاظ شده اند و با کارت تخفیف تغییرات قیمت داشته باشند باید دوباره به قیمت اولیه فروشگاه برگردند
         UPDATE od
            SET od.OFF_PRCT = 0,
                od.OFF_TYPE = NULL,
                od.OFF_KIND = NULL
           FROM dbo.Order_Detail od
          WHERE od.ORDR_CODE = @OrdrCode
            AND NOT EXISTS(
                SELECT *
                  FROM dbo.Robot_Product_Discount d
                 WHERE od.TARF_CODE = d.TARF_CODE
                   AND d.ACTV_TYPE = '002'
                   AND (
                         ( d.OFF_TYPE = '001' /* showprodofftimer */ AND d.REMN_TIME >= GETDATE() ) OR 
                           d.OFF_TYPE != '001'
                   )
          );          
         
	      -- اگر تعداد بیش از یک باشد اطلاعات بروزرسانی میشود
	      IF @n > 0
	      BEGIN
	         -- 1399/04/19
            -- بروزرسانی موجودی جدول کالاها	
            -- کم کردن کالا از سیستم قفسه های کالا
            IF EXISTS (SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */)
            BEGIN
               -- بدست آوردن تعداد محصول درون سبد خرید مشتری
               SELECT @SaleCartNumbDnrm = ISNULL(SUM(od.NUMB), 0)
                 FROM dbo.[Order] o, dbo.Order_Detail od
                WHERE o.ORDR_TYPE = '004'
                  AND o.ORDR_STAT = '001'
                  AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE)
                  AND o.CODE = od.ORDR_CODE
                  AND od.TARF_CODE = @tarfcode
                  AND o.CODE = @OrdrCode;
               
               -- 1399/04/23
               -- قبل از اینکه محصولی از قفسه ها کم شود باید چک کنیم که آیا این تعداد موجودی درون قفسه وجود دارد یا خیر
               IF EXISTS (SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */ AND (rp.CRNT_NUMB_DNRM + @SaleCartNumbDnrm) >= @n )
               BEGIN
                  -- 1399/09/11 * اگر کالا شرایط حداقل خرید داشته باشد
                  SELECT @MinOrdr = ISNULL(rp.MIN_ORDR_DNRM, 1),
                         @CrntNumb = rp.CRNT_NUMB_DNRM + od.NUMB
                    FROM dbo.Robot_Product rp , dbo.Order_Detail od
                   WHERE rp.ROBO_RBID = @Rbid 
                     AND rp.TARF_CODE = @tarfcode
                     AND od.ORDR_CODE = @OrdrCode
                     AND od.TARF_CODE = @tarfcode;
                  
                  -- اگر مشتری موظف به خرید بالا به صورت عمده باشد
                  IF @MinOrdr > 1
                  BEGIN
                     -- اگر کالا نسبت به حداقل خرید موجود باشد
                     IF @CrntNumb >= @MinOrdr
                     BEGIN
                        -- اگر تعداد درخواست خرید مشتری از حداقل خرید کمتر باشد
                        IF @n < @MinOrdr
                           -- باید تعداد خرید را به میزان حداقل خرید تغییر داد
                           SET @n = @MinOrdr
                     END 
                     -- اگر موجودی فعلی از تعداد درخواست مشتری کمتر باشد بایستی تعداد موجود را جایگزین کنیم
                     ELSE IF @CrntNumb < @n
                        SET @n = @CrntNumb
                  END
                  
                  -- 1399/09/07 * اگر متقاضی به عنوان همکار فروش باشد
                  SELECT @SrspCode = NULL;
                  IF EXISTS (
                     SELECT sp.CODE
                       FROM dbo.Service_Robot_Seller_Partner sp
                      where sp.CHAT_ID = @ChatId
                        AND sp.TARF_CODE_DNRM = @tarfcode
                        AND sp.STAT = '002'
                  )
                  BEGIN 
                     -- بدست آوردن قیمت همکار و کد
                     SELECT @SrspCode = sp.CODE, 
                            @ExpnPric = sp.EXPN_PRIC,
                            @BuyPric = sp.BUY_PRIC,
                            @PrftPric = sp.PRFT_PRIC_DNRM
                       FROM dbo.Service_Robot_Seller_Partner sp
                      where sp.CHAT_ID = @ChatId
                        AND sp.TARF_CODE_DNRM = @tarfcode
                        AND sp.STAT = '002';
                     
                     SET @ExtrPrct = @ExpnPric * @TaxPrct / 100;
                     SET @OrdrCmnt = N'محصول با قیمت همکار در نظر گرفته شده';
                     -- زمانی که قیمت همکار داده میشود دیگر تخفیف در نظر گرفته نمیشود
                     SET @OffPrct = 0;
                     SET @offType = '000';
                     
                     -- بروزرسانی اطلاعت اقلام فاکتور
                     UPDATE dbo.Order_Detail
	                     SET TARF_DATE = @TarfDate,
	                         EXPN_PRIC = @ExpnPric,
	                         EXTR_PRCT = @ExtrPrct,
	                         BUY_PRIC_DNRM = @BuyPric,
	                         PRFT_PRIC_DNRM = @PrftPric,
	                         SRSP_CODE = @SrspCode,
                            NUMB = @n,
                            ORDR_DESC = @OrdrDesc,
                            ORDR_CMNT = @OrdrCmnt,
                            OFF_PRCT = ISNULL(@OffPrct, 0),
                            OFF_TYPE = ISNULL(OFF_TYPE, '000')
	                   WHERE ORDR_CODE = @OrdrCode
	                     AND TARF_CODE = @tarfcode;
                  END 
                  ELSE
                  BEGIN 
                     -- 1399/09/07 * اگر قیمت همکار حذف شده باشد جهت بروزرسانی
                     -- IF EXISTS(SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @tarfcode AND od.SRSP_CODE IS NOT NULL)
                     BEGIN
                        SELECT @BuyPric = rp.BUY_PRIC
                              ,@PrftPric = rp.PRFT_PRIC_DNRM
                          FROM dbo.Robot_Product rp
                        WHERE rp.ROBO_RBID = @Rbid
                          AND rp.TARF_CODE = @tarfcode;
                     END
                     -- بروزرسانی اطلاعت اقلام فاکتور
                     UPDATE dbo.Order_Detail
	                     SET TARF_DATE = @TarfDate,
	                         EXPN_PRIC = @ExpnPric,
	                         EXTR_PRCT = @ExtrPrct,
	                         BUY_PRIC_DNRM = @BuyPric,
	                         PRFT_PRIC_DNRM = @PrftPric,
                            NUMB = @n,
                            ORDR_DESC = @OrdrDesc,
                            ORDR_CMNT = @OrdrCmnt,
                            OFF_PRCT = ISNULL(@OffPrct, 0),
                            OFF_TYPE = ISNULL(OFF_TYPE, '000'),
                            SRSP_CODE = NULL
	                   WHERE ORDR_CODE = @OrdrCode
	                     AND TARF_CODE = @tarfcode;
                  END 
                  
	               -- بدست آوردن تعداد محصول درون سبدهای خرید دیگر مشتریان
	               SELECT @SaleCartNumbDnrm = ISNULL(SUM(od.NUMB), 0)
                    FROM dbo.[Order] o, dbo.Order_Detail od
                   WHERE o.ORDR_TYPE = '004'
                     AND o.ORDR_STAT = '001'
                     AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE)
                     AND o.CODE = od.ORDR_CODE
                     AND od.TARF_CODE = @tarfcode
                     AND o.CODE != @OrdrCode;
	                  
                  -- در این مرحله جدول موجودی کالا را بروزرسانی میکنیم
                  UPDATE p
                     SET p.CRNT_NUMB_DNRM = WREH_INVR_NUMB - (SALE_NUMB_DNRM + @SaleCartNumbDnrm + @n)
                    FROM dbo.Service_Robot_Seller_Product p
                   WHERE p.TARF_CODE = @tarfcode;
                   
                  -- 1399/05/01
                  -- اگر کالایی که داریم بررسی میکنیم کالای هدیه باشد و خودش دوباره کالای هدیه داشته باشد نباید آنها را درون لیست قرار دهیم
                  IF ISNULL(@IsLoopOprt, '001') = '001'
                  BEGIN 
                     -- اگر کالا هدیه داشته باشد باید آن را اضافه کنیم
                     DECLARE C$GiftProds1 CURSOR FOR
                        SELECT rp.TARF_CODE
                          FROM dbo.Service_Robot_Seller_Product_Gift pg, dbo.Service_Robot_Seller_Product p, dbo.Robot_Product rp
                         WHERE pg.TARF_CODE_DNRM = @tarfcode
                           AND pg.SSPG_CODE = p.CODE
                           AND pg.STAT = '002'
                           AND p.PROD_TYPE = '002'
                           AND p.CRNT_NUMB_DNRM > 0
                           AND p.TARF_CODE = rp.TARF_CODE
                           AND rp.ROBO_RBID = @Rbid
                           AND rp.STAT = '002';
                     
                     OPEN [C$GiftProds1];
                     L$GiftProds1:
                     FETCH [C$GiftProds1] INTO @GiftTarfCode;
                     
                     IF @@FETCH_STATUS <> 0
                        GOTO L$EndGiftProds1;
                     
                     IF NOT EXISTS (SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @GiftTarfCode)
                     BEGIN
                        SET @xTemp = (
                           SELECT @Rbid AS '@rbid',
                                  @ChatId AS '@chatid',
                                  @BaseUssdCode AS '@ussdcode',
                                  @OrdrCode AS '@ordrcode',
                                  @GiftTarfCode AS '@input',
                                  '002' AS '@isloopoprt'
                             FOR XML PATH('Action'), ROOT('Cart')                    
                        );
                        EXEC dbo.SAVE_S05C_P @X = @xTemp, -- xml
                           @xRet = @xTemp OUTPUT -- xml
                     END
                     --ELSE
                     --BEGIN
                     --   SELECT @n = od.NUMB + @n
                     --     FROM dbo.Order_Detail od
                     --    WHERE od.ORDR_CODE = @OrdrCode
                     --      AND od.TARF_CODE = @GiftTarfCode
                     --END  
                     
                     UPDATE dbo.Order_Detail
                        SET NUMB = @n,
                            OFF_PRCT = 100,
                            OFF_TYPE = '007',
                            OFF_KIND = '003'
                      WHERE ORDR_CODE = @OrdrCode
                        AND TARF_CODE = @GiftTarfCode;
                     
                     -- 1399/05/03
                     -- بروزرسانی موجودی جدول کالاها	                  
                     UPDATE p
                        SET p.CRNT_NUMB_DNRM = p.WREH_INVR_NUMB - (p.SALE_NUMB_DNRM + (p.SALE_CART_NUMB_DNRM/* - od.NUMB*/))
                       FROM dbo.Service_Robot_Seller_Product p, dbo.Order_Detail od
                      WHERE p.TARF_CODE = @GiftTarfCode
                        AND p.TARF_CODE = od.TARF_CODE
                        AND od.ORDR_CODE = @OrdrCode
                        AND p.PROD_TYPE = '002';

                     GOTO L$GiftProds1;
                     L$EndGiftProds1:
                     CLOSE [C$GiftProds1];
                     DEALLOCATE [C$GiftProds1];
                  END
               END 
               -- اگر تعداد درخواستی مشتری از تعداد قفسه های موجود بیشتر باشد
               ELSE IF EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */ AND rp.CRNT_NUMB_DNRM > 0 AND @n > rp.CRNT_NUMB_DNRM)
               BEGIN
                  SET @xRet = (
                      SELECT 'Lack of inventory' AS '@rsltdesc',
                             '004' AS '@rsltcode',
                             @OrdrCode AS '@ordrcode',
                             @tarfcode AS '@tarfcode',
                             N'تعداد مد نظر شما از تعداد موجودی کالا  بیشتر می باشد، لطفا تعداد خود را تصحیح کنید'
                         FOR XML PATH('Message'), ROOT('Result')
                  );
                  
                  GOTO L$End;
               END
               -- اگر موجودی کالا درون قفسه های کالا صفر شده باشد
               ELSE IF EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */ AND rp.CRNT_NUMB_DNRM = 0)
               BEGIN
                  --RAISERROR(N'برای کالای درخواستی شما موجودی کافی وجود ندارد', 1, 16);
                  SET @xRet = (
                      SELECT 'Lack of inventory' AS '@rsltdesc',
                             '003' AS '@rsltcode',
                             @OrdrCode AS '@ordrcode',
                             @tarfcode AS '@tarfcode',
                             N'کالا مورد نظر شما موجود نیست'
                         FOR XML PATH('Message'), ROOT('Result')
                  );
                  
                  -- 1394/04/25
                  -- قبل از پایان کار بایستی اطلاعات مروبط به مشتری جهت اینکه در صورت موجود شدن کالا با اطلاع شود را قرار میدهیم.
                  INSERT INTO dbo.Service_Robot_Product_Signal
                  (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RBPR_CODE ,CODE ,SEND_STAT, CHCK_RQST_NUMB)
                  SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, rp.CODE, dbo.GNRT_NVID_U(), '002', 1
                    FROM dbo.Service_Robot sr, dbo.Robot_Product rp
                   WHERE sr.ROBO_RBID = @Rbid
                     AND sr.CHAT_ID = @ChatId
                     AND rp.ROBO_RBID = sr.ROBO_RBID
                     AND rp.TARF_CODE = @tarfcode
                     AND NOT EXISTS (
                           SELECT *
                             FROM dbo.Service_Robot_Product_Signal ps
                            WHERE ps.SRBT_ROBO_RBID = @Rbid
                              AND ps.CHAT_ID = @ChatId
                              AND ps.TARF_CODE_DNRM = @tarfcode
                              AND ps.SEND_STAT IN ('002', '005')
                         );
                         
                  -- 1399/05/05
                  -- اگر ردیف کالا برای مشتری قبلا ثبت شده باشد فقط کافیست که تعداد دفعات را بروزرسانی کنیم
                  IF @@ROWCOUNT = 0
                     UPDATE s
                        SET s.CHCK_RQST_NUMB += 1
                       FROM dbo.Service_Robot_Product_Signal s
                      WHERE SRBT_ROBO_RBID = @Rbid
                        AND TARF_CODE_DNRM = @tarfcode
                        AND s.CHAT_ID = @ChatId
                        AND SEND_STAT IN ('002', '005');
                  
                  -- 1399/04/26 * 3:16 PM
                  IF EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */ AND rp.SALE_CART_NUMB_DNRM = 0)
                  BEGIN
                     -- 1399/04/26
                     -- اطلاع رسانی به واحد های مشاغل فروشگاه
                     SET @xTemp = (
                         SELECT @Rbid AS '@rbid',
                                @ChatId AS 'Order/@chatid',
                                @OrdrCode AS 'Order/@code',
                                '012' AS 'Order/@type',
                                'nomoreprodtosale' AS 'Order/@oprt',
                                @tarfcode AS 'Order/@valu'
                            FOR XML PATH('Robot')
                     );
                     EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
                  END 
                  GOTO L$End;
               END 
            END
            -- اگر کالا فیزیکی نباشد مثلا خدماتی باشد
            ELSE 
            BEGIN
               -- 1399/09/07 * اگر متقاضی به عنوان همکار فروش باشد
               SELECT @SrspCode = NULL;
               IF EXISTS (
                  SELECT sp.CODE
                    FROM dbo.Service_Robot_Seller_Partner sp
                   where sp.CHAT_ID = @ChatId
                     AND sp.TARF_CODE_DNRM = @tarfcode
                     AND sp.STAT = '002'
               )
               BEGIN 
                  -- بدست آوردن قیمت همکار و کد
                  SELECT @SrspCode = sp.CODE, 
                         @ExpnPric = sp.EXPN_PRIC,
                         @BuyPric = sp.BUY_PRIC,
                         @PrftPric = sp.PRFT_PRIC_DNRM
                    FROM dbo.Service_Robot_Seller_Partner sp
                   where sp.CHAT_ID = @ChatId
                     AND sp.TARF_CODE_DNRM = @tarfcode
                     AND sp.STAT = '002';
                  
                  SET @ExtrPrct = @ExpnPric * @TaxPrct / 100;
                  SET @OrdrCmnt = N'محصول با قیمت همکار در نظر گرفته شده';
                  -- زمانی که قیمت همکار داده میشود دیگر تخفیف در نظر گرفته نمیشود
                  SET @OffPrct = 0;
                  SET @offType = '000';                  
                  
                  -- بروزرسانی اطلاعت اقلام فاکتور
                  UPDATE dbo.Order_Detail
                     SET TARF_DATE = @TarfDate,
                         EXPN_PRIC = @ExpnPric,
                         EXTR_PRCT = @ExtrPrct,
                         BUY_PRIC_DNRM = @BuyPric,
                         PRFT_PRIC_DNRM = @PrftPric,
                         SRSP_CODE = @SrspCode,
                         NUMB = @n,
                         ORDR_DESC = @OrdrDesc,
                         ORDR_CMNT = @OrdrCmnt,
                         OFF_PRCT = ISNULL(@OffPrct, 0),
                         OFF_TYPE = ISNULL(OFF_TYPE, '000')
                   WHERE ORDR_CODE = @OrdrCode
                     AND TARF_CODE = @tarfcode;
               END 
               ELSE
               BEGIN 
                  -- 1399/09/07 * اگر قیمت همکار حذف شده باشد جهت بروزرسانی
                  --IF EXISTS(SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @tarfcode AND od.SRSP_CODE IS NOT NULL)
                  BEGIN
                     SELECT @BuyPric = rp.BUY_PRIC
                           ,@PrftPric = rp.PRFT_PRIC_DNRM
                       FROM dbo.Robot_Product rp
                     WHERE rp.ROBO_RBID = @Rbid
                       AND rp.TARF_CODE = @tarfcode;
                  END
                  -- بروزرسانی اطلاعت اقلام فاکتور
                  UPDATE dbo.Order_Detail
                     SET TARF_DATE = @TarfDate,
                         EXPN_PRIC = @ExpnPric,
                         EXTR_PRCT = @ExtrPrct,
                         BUY_PRIC_DNRM = @BuyPric,
                         PRFT_PRIC_DNRM = @PrftPric,
                         NUMB = @n,
                         ORDR_DESC = @OrdrDesc,
                         ORDR_CMNT = @OrdrCmnt,
                         OFF_PRCT = ISNULL(@OffPrct, 0),
                         OFF_TYPE = ISNULL(OFF_TYPE, '000'),
                         SRSP_CODE = NULL
                   WHERE ORDR_CODE = @OrdrCode
                     AND TARF_CODE = @tarfcode;
               END
               -- بروزرسانی اطلاعت اقلام فاکتور
               --UPDATE dbo.Order_Detail
               --   SET TARF_DATE = @TarfDate,
               --       EXPN_PRIC = @ExpnPric,
               --       EXTR_PRCT = @ExtrPrct,
               --       NUMB = @n,
               --       ORDR_DESC = @OrdrDesc,
               --       ORDR_CMNT = @OrdrCmnt,
               --       OFF_PRCT = ISNULL(@OffPrct, 0),
               --       OFF_TYPE = ISNULL(OFF_TYPE, '000')
               -- WHERE ORDR_CODE = @OrdrCode
               --   AND TARF_CODE = @tarfcode;
               
               -- 1399/05/01
               -- اگر کالایی که داریم بررسی میکنیم کالای هدیه باشد و خودش دوباره کالای هدیه داشته باشد نباید آنها را درون لیست قرار دهیم
               IF ISNULL(@IsLoopOprt, '001') = '001'
               BEGIN 
                  -- اگر کالا هدیه داشته باشد باید آن را اضافه کنیم
                  DECLARE C$GiftProds2 CURSOR FOR
                     SELECT rp.TARF_CODE
                       FROM dbo.Service_Robot_Seller_Product_Gift pg, dbo.Service_Robot_Seller_Product p, dbo.Robot_Product rp
                      WHERE pg.TARF_CODE_DNRM = @tarfcode
                        AND pg.SSPG_CODE = p.CODE
                        AND pg.STAT = '002'
                        AND p.PROD_TYPE = '001'
                        --AND p.CRNT_NUMB_DNRM > 0
                        AND p.TARF_CODE = rp.TARF_CODE
                        AND rp.ROBO_RBID = @Rbid
                        AND rp.STAT = '002';
                  
                  OPEN [C$GiftProds2];
                  L$GiftProds2:
                  FETCH [C$GiftProds2] INTO @GiftTarfCode;
                  
                  IF @@FETCH_STATUS <> 0
                     GOTO L$EndGiftProds2;
                  
                  IF NOT EXISTS (SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @GiftTarfCode)
                  BEGIN
                     SET @xTemp = (
                        SELECT @Rbid AS '@rbid',
                               @ChatId AS '@chatid',
                               @BaseUssdCode AS '@ussdcode',
                               @OrdrCode AS '@ordrcode',
                               @GiftTarfCode AS '@input',
                               '002' AS '@isloopoprt'
                          FOR XML PATH('Action'), ROOT('Cart')                    
                     );
                     EXEC dbo.SAVE_S05C_P @X = @xTemp, -- xml
                        @xRet = @xTemp OUTPUT -- xml
                  END 
                  --ELSE
                  --BEGIN
                  --   SELECT @n = od.NUMB + @n
                  --     FROM dbo.Order_Detail od
                  --    WHERE od.ORDR_CODE = @OrdrCode
                  --      AND od.TARF_CODE = @GiftTarfCode
                  --END  
                  
                  UPDATE dbo.Order_Detail
                     SET NUMB = @n,
                         OFF_PRCT = 100,
                         OFF_TYPE = '007',
                         OFF_KIND = '003'
                   WHERE ORDR_CODE = @OrdrCode
                     AND TARF_CODE = @GiftTarfCode;
                  
                  -- 1399/05/03
                  -- بروزرسانی موجودی جدول کالاها	                  
                  UPDATE p
                     SET p.CRNT_NUMB_DNRM = p.WREH_INVR_NUMB - (p.SALE_NUMB_DNRM + (p.SALE_CART_NUMB_DNRM/* - od.NUMB*/))
                    FROM dbo.Service_Robot_Seller_Product p, dbo.Order_Detail od
                   WHERE p.TARF_CODE = @GiftTarfCode
                     AND p.TARF_CODE = od.TARF_CODE
                     AND od.ORDR_CODE = @OrdrCode
                     AND p.PROD_TYPE = '002';

                  GOTO L$GiftProds2;
                  L$EndGiftProds2:
                  CLOSE [C$GiftProds2];
                  DEALLOCATE [C$GiftProds2];
               END
            END
         END 
	      ELSE
	      BEGIN
	         -- در غیر اینصورت اطلاعات از صورتحساب حذف میشود
	         SET @del = 1;
	         GOTO L$DeleteTarfCode;
	      END 
	         
	      -- اطلاعات بروزرسانی شد
	      SET @TypeCode = '003'
	   END	   
	   ELSE IF @OrdrType = '004' /* درخواست ثبت سفارش */
	   BEGIN 
         -- محاسبه زمان انجام عملیات تعرفه   
         IF(@d != 0)
            SET @TarfDate = DATEADD(DAY, @d, GETDATE());
         ELSE IF @dt IS NOT NULL
            SET @TarfDate = @dt;
         ELSE 
            SET @TarfDate = GETDATE();
            
	      -- اگر کد تعرفه جدید باشد
	      IF @RqtpCode IN ( '001' , '009' )
	      BEGIN
	         SELECT @OrdrCmnt = N'👈 ثبت دوره غیرحضوری',
	                @OrdrDesc = 
	                  CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'👱 ' WHEN '002' THEN N'👩 ' END + 
	                  N'*'+ f.NAME_DNRM + N'* ' +
	                  N'📔 *'+ m.MTOD_DESC + N'* ' +
	                  N'📦 *' + cb.CTGY_DESC + N'* ' +
	                  CASE s.VALU WHEN '001' THEN N' 👬 ' WHEN '002' THEN N' 👭 ' WHEN '003' THEN N' 👫 ' END +
	                  N'[ *' + s.DOMN_DESC + N'* ] ☀️ [ *' + d.DOMN_DESC + N'* ] [ *' +  CAST(cm.STRT_TIME AS VARCHAR(5)) + N'* ] - [ *' + CAST(cm.END_TIME AS VARCHAR(5)) + N'* ]' + 
	                  (
	                     SELECT N'[ *' + d.DOMN_DESC + N'* ] ,'
	                       FROM iScsc.dbo.Club_Method_Weekday cmw, iScsc.dbo.[D$WKDY] d
	                      WHERE cmw.CBMT_CODE = cm.CODE
	                        AND cmw.WEEK_DAY = d.VALU
	                        AND cmw.STAT = '002'
	                        ORDER BY d.VALU
	                        FOR XML PATH('')	                    
	                  ) + CHAR(10) + 
	                  N'📆 [ *شروع دوره* ] *' + iRoboTech.dbo.GET_MTOS_U(@TarfDate) + N'*',
	                  @ExpnPric = cb.PRIC
              FROM iScsc.dbo.Method m, iScsc.dbo.Category_Belt cb, iScsc.dbo.Club_Method cm, iScsc.dbo.Fighter f, iScsc.dbo.[D$SXTP] s, iScsc.dbo.[D$DYTP] d
             WHERE m.CODE = cb.MTOD_CODE
               AND m.CODE = cm.MTOD_CODE
               AND cm.COCH_FILE_NO = f.FILE_NO
               AND cm.SEX_TYPE = s.VALU
               AND cm.DAY_TYPE = d.VALU
               AND m.NATL_CODE + cb.NATL_CODE + cm.NATL_CODE = @tarfcode
               AND m.MTOD_STAT = '002'
               AND cm.MTOD_STAT = '002'
               AND f.ACTV_TAG_DNRM >= '101';
         END
         ELSE IF @RqtpCode = '016'
         BEGIN
            SELECT @ExpnPric = e.PRIC,
                   @OrdrCmnt = CAST(e.ORDR_ITEM AS VARCHAR(4000)),
                   @OrdrDesc = e.EXPN_DESC
              FROM iScsc.dbo.Expense e, iScsc.dbo.Expense_Type et, iScsc.dbo.Request_Requester rr
             WHERE e.EXTP_CODE = et.CODE
               AND et.RQRQ_CODE = rr.CODE
               AND rr.RQTP_CODE = '016'
               AND rr.RQTT_CODE = '001' 
               AND e.EXPN_STAT = '002'   
               AND CAST(e.ORDR_ITEM AS VARCHAR(MAX)) = @tarfcode
         END
         
         SET @ExtrPrct = @ExpnPric * @TaxPrct / 100;
         
         -- اگر هزینه درون ربات با تخفیف قرار گرفته شده باشد	      
         SELECT TOP 1 @RbpdCode = rpd.CODE, @OffPrct = rpd.OFF_PRCT, @offType = rpd.OFF_TYPE
           FROM dbo.Robot_Product_Discount rpd
          WHERE rpd.ROBO_RBID = @Rbid
            AND rpd.TARF_CODE = @tarfcode
            AND rpd.ACTV_TYPE = '002' --  فعال باشد
          ORDER BY rpd.OFF_TYPE;
         
         -- در درون فاکتور رسید پرداخت توسط فروشگاه تایید شده باشد فاکتور به هیچ عنوان قابل ویرایش نیست و مشتری موظف به پرداخت کل فاکتور و پایانی کردن سفارش می باشد
         IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '005' AND os.CONF_STAT = '002')
         BEGIN
            SET @xRet = (
                SELECT 'successful' AS '@rsltdesc',
                       '002' AS '@rsltcode',
                       @OrdrCode AS '@ordrcode',
                       N'فاکتور دارای رسید پرداخت تایید شده توسط فروشنده می باشد، شما نمی توانید تغییراتی درون فاکتور ایجاد کنید، لطفا فاکتور خود را پایانی کنید'
                   FOR XML PATH('Message'), ROOT('Result')
            );
            
            GOTO L$End;
         END
         
         -- برگشت مبلغ به کارت اعتباری مشتری
         UPDATE g 
            SET g.TEMP_AMNT_USE = 0
           FROM dbo.Service_Robot_Gift_Card g, dbo.Order_State os
          WHERE g.GCID = os.GIFC_GCID
            AND os.ORDR_CODE = @OrdrCode;
         
         -- برگشت مبلغ کسر شده از کیف پول
         UPDATE w
            SET w.TEMP_AMNT_USE = 0
           FROM dbo.Wallet w, dbo.Wallet_Detail wd
          WHERE w.CODE = wd.WLET_CODE
            AND wd.ORDR_CODE = @OrdrCode;
         
         -- اگر اطلاعات فاکتور عوض شود در صورتی که کد تخفیف ثبت کرده باشیم باید کد تخفیف را حذف کنیم
         -- هر گونه ردیف در مورد تخفیف / واریزی / رسید پرداخت تایید نشده را حذف میکنیم
         DELETE dbo.Order_State
          WHERE ORDR_CODE = @OrdrCode
            AND AMNT_TYPE NOT IN ('005' /* رسید های پرداخت نیاز به پاک شدن ندارند */);
          
         DELETE dbo.Wallet_Detail
          WHERE ORDR_CODE = @OrdrCode
            AND CONF_STAT = '003';
         
         -- اگر کالاهایی که در قسمت تخفیف عادی لحاظ شده اند و با کارت تخفیف تغییرات قیمت داشته باشند باید دوباره به قیمت اولیه فروشگاه برگردند
         UPDATE od
            SET od.OFF_PRCT = 0,
                od.OFF_TYPE = NULL,
                od.OFF_KIND = NULL
           FROM dbo.Order_Detail od
          WHERE od.ORDR_CODE = @OrdrCode
            AND NOT EXISTS(
                SELECT *
                  FROM dbo.Robot_Product_Discount d
                 WHERE od.TARF_CODE = d.TARF_CODE
                   AND d.ACTV_TYPE = '002'
                   AND (
                         ( d.OFF_TYPE = '001' /* showprodofftimer */ AND d.REMN_TIME >= GETDATE() ) OR 
                           d.OFF_TYPE != '001'
                   )
          );         
         
         -- 1399/04/19
         -- بروزرسانی موجودی جدول کالاها	
         -- کم کردن کالا از سیستم قفسه های کالا
         IF EXISTS (SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */)
         BEGIN
            -- بدست آوردن تعداد محصول درون سبد خرید مشتری
            SELECT @SaleCartNumbDnrm = ISNULL(SUM(od.NUMB), 0)
              FROM dbo.[Order] o, dbo.Order_Detail od
             WHERE o.ORDR_TYPE = '004'
               AND o.ORDR_STAT = '001'
               AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE)
               AND o.CODE = od.ORDR_CODE
               AND od.TARF_CODE = @tarfcode
               AND o.CODE = @OrdrCode;
               
            -- 1399/04/23
            -- قبل از اینکه محصولی از قفسه ها کم شود باید چک کنیم که آیا این تعداد موجودی درون قفسه وجود دارد یا خیر
            IF EXISTS (SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */ AND (rp.CRNT_NUMB_DNRM + @SaleCartNumbDnrm) >= @n )
            BEGIN
               -- 1399/09/11 * اگر کالا شرایط حداقل خرید داشته باشد
               SELECT @MinOrdr = ISNULL(rp.MIN_ORDR_DNRM, 1),
                      @CrntNumb = rp.CRNT_NUMB_DNRM
                 FROM dbo.Robot_Product rp 
                WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode;
               
               -- اگر مشتری موظف به خرید بالا به صورت عمده باشد
               IF @MinOrdr > 1
               BEGIN
                  -- اگر کالا نسبت به حداقل خرید موجود باشد
                  IF @CrntNumb >= @MinOrdr
                  BEGIN
                     -- اگر تعداد درخواست خرید مشتری از حداقل خرید کمتر باشد
                     IF @n < @MinOrdr
                        -- باید تعداد خرید را به میزان حداقل خرید تغییر داد
                        SET @n = @MinOrdr
                  END 
                  -- اگر موجودی فعلی از تعداد درخواست مشتری کمتر باشد بایستی تعداد موجود را جایگزین کنیم
                  ELSE IF @CrntNumb < @n
                     SET @n = @CrntNumb
               END 
               
               -- 1399/09/07 * اگر متقاضی به عنوان همکار فروش باشد
               SELECT @SrspCode = NULL;
               IF EXISTS (
                  SELECT sp.CODE
                    FROM dbo.Service_Robot_Seller_Partner sp
                   where sp.CHAT_ID = @ChatId
                     AND sp.TARF_CODE_DNRM = @tarfcode
                     AND sp.STAT = '002'
               )
               BEGIN 
                  -- بدست آوردن قیمت همکار و کد
                  SELECT @SrspCode = sp.CODE, 
                         @ExpnPric = sp.EXPN_PRIC,
                         @BuyPric = sp.BUY_PRIC,
                         @PrftPric = sp.PRFT_PRIC_DNRM
                    FROM dbo.Service_Robot_Seller_Partner sp
                   where sp.CHAT_ID = @ChatId
                     AND sp.TARF_CODE_DNRM = @tarfcode
                     AND sp.STAT = '002';
                  
                  SET @ExtrPrct = @ExpnPric * @TaxPrct / 100;
                  SET @OrdrCmnt = N'محصول با قیمت همکار در نظر گرفته شده';
                  -- زمانی که قیمت همکار داده میشود دیگر تخفیف در نظر گرفته نمیشود
                  SET @OffPrct = 0;
                  SET @offType = '000';
                  
                  -- درج اطلاعات در جدول ردیف درخواست
                  INSERT INTO dbo.Order_Detail (ORDR_CODE, ELMN_TYPE, ORDR_DESC, ORDR_CMNT, EXPN_PRIC, EXTR_PRCT, TAX_PRCT, NUMB, TARF_CODE, TARF_DATE, RQTP_CODE_DNRM, BASE_USSD_CODE, OFF_PRCT, OFF_TYPE, SRSP_CODE, BUY_PRIC_DNRM, PRFT_PRIC_DNRM)
                  VALUES(@OrdrCode, '001', @OrdrDesc, @OrdrCmnt, @ExpnPric, @ExtrPrct, @TaxPrct, @n, @tarfcode, @TarfDate, @RqtpCode, @BaseUssdCode, @OffPrct, @offType, @SrspCode, @BuyPric, @PrftPric);
               END 
               ELSE
               BEGIN 
                  -- درج اطلاعات در جدول ردیف درخواست
                  INSERT INTO dbo.Order_Detail (ORDR_CODE, ELMN_TYPE, ORDR_DESC, ORDR_CMNT, EXPN_PRIC, EXTR_PRCT, TAX_PRCT, NUMB, TARF_CODE, TARF_DATE, RQTP_CODE_DNRM, BASE_USSD_CODE, OFF_PRCT, OFF_TYPE)
                  VALUES(@OrdrCode, '001', @OrdrDesc, @OrdrCmnt, @ExpnPric, @ExtrPrct, @TaxPrct, @n, @tarfcode, @TarfDate, @RqtpCode, @BaseUssdCode, @OffPrct, @offType);
               END 
               
               -- بدست آوردن تعداد محصول درون سبدهای خرید دیگر مشتریان
               SELECT @SaleCartNumbDnrm = ISNULL(SUM(od.NUMB), 0)
                 FROM dbo.[Order] o, dbo.Order_Detail od
                WHERE o.ORDR_TYPE = '004'
                  AND o.ORDR_STAT = '001'
                  AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE)
                  AND o.CODE = od.ORDR_CODE
                  AND od.TARF_CODE = @tarfcode
                  AND o.CODE != @OrdrCode;
         
               -- در این مرحله جدول موجودی کالا را بروزرسانی میکنیم
               UPDATE p
                  SET p.CRNT_NUMB_DNRM = WREH_INVR_NUMB - (SALE_NUMB_DNRM + @SaleCartNumbDnrm + @n)
                 FROM dbo.Service_Robot_Seller_Product p
                WHERE p.TARF_CODE = @tarfcode;               
               
               -- 1399/05/01
               -- اگر کالایی که داریم بررسی میکنیم کالای هدیه باشد و خودش دوباره کالای هدیه داشته باشد نباید آنها را درون لیست قرار دهیم
               IF ISNULL(@IsLoopOprt, '001') = '001'
               BEGIN 
                  -- اگر کالا هدیه داشته باشد باید آن را اضافه کنیم
                  DECLARE C$GiftProds3 CURSOR FOR
                     SELECT rp.TARF_CODE
                       FROM dbo.Service_Robot_Seller_Product_Gift pg, dbo.Service_Robot_Seller_Product p, dbo.Robot_Product rp
                      WHERE pg.TARF_CODE_DNRM = @tarfcode
                        AND pg.SSPG_CODE = p.CODE
                        AND pg.STAT = '002'
                        AND p.PROD_TYPE = '002'
                        AND p.CRNT_NUMB_DNRM > 0
                        AND p.TARF_CODE = rp.TARF_CODE
                        AND rp.ROBO_RBID = @Rbid
                        AND rp.STAT = '002';
                  
                  OPEN [C$GiftProds3];
                  L$GiftProds3:
                  FETCH [C$GiftProds3] INTO @GiftTarfCode;
                  
                  IF @@FETCH_STATUS <> 0
                     GOTO L$EndGiftProds3;
                  
                  IF NOT EXISTS (SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @GiftTarfCode)
                  BEGIN
                     SET @xTemp = (
                        SELECT @Rbid AS '@rbid',
                               @ChatId AS '@chatid',
                               @BaseUssdCode AS '@ussdcode',
                               @OrdrCode AS '@ordrcode',
                               @GiftTarfCode AS '@input',
                               '002' AS '@isloopoprt'
                          FOR XML PATH('Action'), ROOT('Cart')                    
                     );
                     EXEC dbo.SAVE_S05C_P @X = @xTemp, -- xml
                        @xRet = @xTemp OUTPUT -- xml
                  END 
                  --ELSE
                  --BEGIN
                  --   SELECT @n = od.NUMB + @n
                  --     FROM dbo.Order_Detail od
                  --    WHERE od.ORDR_CODE = @OrdrCode
                  --      AND od.TARF_CODE = @GiftTarfCode
                  --END  
                  
                  UPDATE dbo.Order_Detail
                     SET NUMB = @n,
                         OFF_PRCT = 100,
                         OFF_TYPE = '007',
                         OFF_KIND = '003'
                   WHERE ORDR_CODE = @OrdrCode
                     AND TARF_CODE = @GiftTarfCode;
                  
                  -- 1399/05/03
                  -- بروزرسانی موجودی جدول کالاها	                  
                  UPDATE p
                     SET p.CRNT_NUMB_DNRM = p.WREH_INVR_NUMB - (p.SALE_NUMB_DNRM + (p.SALE_CART_NUMB_DNRM/* - od.NUMB*/))
                    FROM dbo.Service_Robot_Seller_Product p, dbo.Order_Detail od
                   WHERE p.TARF_CODE = @GiftTarfCode
                     AND p.TARF_CODE = od.TARF_CODE
                     AND od.ORDR_CODE = @OrdrCode
                     AND p.PROD_TYPE = '002';

                  GOTO L$GiftProds3;
                  L$EndGiftProds3:
                  CLOSE [C$GiftProds3];
                  DEALLOCATE [C$GiftProds3];
               END
            END 
            -- اگر تعداد درخواستی مشتری از تعداد قفسه های موجود بیشتر باشد
            ELSE IF EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */ AND rp.CRNT_NUMB_DNRM > 0 AND @n > rp.CRNT_NUMB_DNRM)
            BEGIN
               SET @xRet = (
                   SELECT 'Lack of inventory' AS '@rsltdesc',
                          '004' AS '@rsltcode',
                          @OrdrCode AS '@ordrcode',
                          @tarfcode AS '@tarfcode',
                          N'تعداد مد نظر شما از تعداد موجودی کالا  بیشتر می باشد، لطفا تعداد خود را تصحیح کنید'
                      FOR XML PATH('Message'), ROOT('Result')
               );
               
               GOTO L$End;
            END
            -- اگر موجودی کالا درون قفسه های کالا صفر شده باشد
            ELSE IF EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */ AND rp.CRNT_NUMB_DNRM = 0)
            BEGIN
               --RAISERROR(N'برای کالای درخواستی شما موجودی کافی وجود ندارد', 1, 16);
               SET @xRet = (
                   SELECT 'Lack of inventory' AS '@rsltdesc',
                          '003' AS '@rsltcode',
                          @OrdrCode AS '@ordrcode',
                          @tarfcode AS '@tarfcode',
                          N'کالا مورد نظر شما موجود نیست'
                      FOR XML PATH('Message'), ROOT('Result')
               );
               
               -- 1394/04/25
               -- قبل از پایان کار بایستی اطلاعات مروبط به مشتری جهت اینکه در صورت موجود شدن کالا با اطلاع شود را قرار میدهیم.
               INSERT INTO dbo.Service_Robot_Product_Signal
               (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RBPR_CODE ,CODE ,SEND_STAT, CHCK_RQST_NUMB)
               SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, rp.CODE, dbo.GNRT_NVID_U(), '002', 1
                 FROM dbo.Service_Robot sr, dbo.Robot_Product rp
                WHERE sr.ROBO_RBID = @Rbid
                  AND sr.CHAT_ID = @ChatId
                  AND rp.ROBO_RBID = sr.ROBO_RBID
                  AND rp.TARF_CODE = @tarfcode
                  AND NOT EXISTS (
                        SELECT *
                          FROM dbo.Service_Robot_Product_Signal ps
                         WHERE ps.SRBT_ROBO_RBID = @Rbid
                           AND ps.CHAT_ID = @ChatId
                           AND ps.TARF_CODE_DNRM = @tarfcode
                           AND ps.SEND_STAT IN ('002', '005')
                      );
               
               -- 1399/05/05
               -- اگر ردیف کالا برای مشتری قبلا ثبت شده باشد فقط کافیست که تعداد دفعات را بروزرسانی کنیم
               IF @@ROWCOUNT = 0
                  UPDATE s
                     SET s.CHCK_RQST_NUMB += 1
                    FROM dbo.Service_Robot_Product_Signal s
                   WHERE s.SRBT_ROBO_RBID = @Rbid
                     AND s.TARF_CODE_DNRM = @tarfcode
                     AND s.CHAT_ID = @ChatId
                     AND s.SEND_STAT IN ('002', '005');
               
               -- 1399/04/26 * 3:16 PM
               IF EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @tarfcode AND rp.PROD_TYPE_DNRM = '002' /* محصولات فیزیکی */ AND rp.SALE_CART_NUMB_DNRM = 0)
               BEGIN
                  -- 1399/04/26
                  -- اطلاع رسانی به واحد های مشاغل فروشگاه
                  SET @xTemp = (
                      SELECT @Rbid AS '@rbid',
                             @ChatId AS 'Order/@chatid',
                             @OrdrCode AS 'Order/@code',
                             '012' AS 'Order/@type',
                             'nomoreprodtosale' AS 'Order/@oprt',
                             @tarfcode AS 'Order/@valu'
                         FOR XML PATH('Robot')
                  );
                  EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
               END 
               GOTO L$End;
            END 
         END 
         -- اگر کالا فیزیکی نباشد مثلا کالا خدماتی
         ELSE 
         BEGIN
            -- 1399/09/07 * اگر متقاضی به عنوان همکار فروش باشد
            SELECT @SrspCode = NULL;
            IF EXISTS (
               SELECT sp.CODE
                 FROM dbo.Service_Robot_Seller_Partner sp
                where sp.CHAT_ID = @ChatId
                  AND sp.TARF_CODE_DNRM = @tarfcode
                  AND sp.STAT = '002'
            )
            BEGIN 
               -- بدست آوردن قیمت همکار و کد
               SELECT @SrspCode = sp.CODE, 
                      @ExpnPric = sp.EXPN_PRIC,
                      @BuyPric = sp.BUY_PRIC,
                      @PrftPric = sp.PRFT_PRIC_DNRM
                 FROM dbo.Service_Robot_Seller_Partner sp
                where sp.CHAT_ID = @ChatId
                  AND sp.TARF_CODE_DNRM = @tarfcode
                  AND sp.STAT = '002';
               
               SET @ExtrPrct = @ExpnPric * @TaxPrct / 100;
               SET @OrdrCmnt = N'محصول با قیمت همکار در نظر گرفته شده';
               -- زمانی که قیمت همکار داده میشود دیگر تخفیف در نظر گرفته نمیشود
               SET @OffPrct = 0;
               SET @offType = '000';

               -- درج اطلاعات در جدول ردیف درخواست
               INSERT INTO dbo.Order_Detail (ORDR_CODE, ELMN_TYPE, ORDR_DESC, ORDR_CMNT, EXPN_PRIC, EXTR_PRCT, TAX_PRCT, NUMB, TARF_CODE, TARF_DATE, RQTP_CODE_DNRM, BASE_USSD_CODE, OFF_PRCT, OFF_TYPE, SRSP_CODE, BUY_PRIC_DNRM, PRFT_PRIC_DNRM)
               VALUES(@OrdrCode, '001', @OrdrDesc, @OrdrCmnt, @ExpnPric, @ExtrPrct, @TaxPrct, @n, @tarfcode, @TarfDate, @RqtpCode, @BaseUssdCode, @OffPrct, @offType, @SrspCode, @BuyPric, @PrftPric);
            END 
            ELSE
            BEGIN 
               -- درج اطلاعات در جدول ردیف درخواست
               INSERT INTO dbo.Order_Detail (ORDR_CODE, ELMN_TYPE, ORDR_DESC, ORDR_CMNT, EXPN_PRIC, EXTR_PRCT, TAX_PRCT, NUMB, TARF_CODE, TARF_DATE, RQTP_CODE_DNRM, BASE_USSD_CODE, OFF_PRCT, OFF_TYPE)
               VALUES(@OrdrCode, '001', @OrdrDesc, @OrdrCmnt, @ExpnPric, @ExtrPrct, @TaxPrct, @n, @tarfcode, @TarfDate, @RqtpCode, @BaseUssdCode, @OffPrct, @offType);
            END 
            -- درج اطلاعات در جدول ردیف درخواست
            --INSERT INTO dbo.Order_Detail (ORDR_CODE, ELMN_TYPE, ORDR_DESC, ORDR_CMNT, EXPN_PRIC, EXTR_PRCT, TAX_PRCT, NUMB, TARF_CODE, TARF_DATE, RQTP_CODE_DNRM, BASE_USSD_CODE, OFF_PRCT, OFF_TYPE)
            --VALUES(@OrdrCode, '001', @OrdrDesc, @OrdrCmnt, @ExpnPric, @ExtrPrct, @TaxPrct, @n, @tarfcode, @TarfDate, @RqtpCode, @BaseUssdCode, @OffPrct, @offType);
            
            -- 1399/05/01
            -- اگر کالایی که داریم بررسی میکنیم کالای هدیه باشد و خودش دوباره کالای هدیه داشته باشد نباید آنها را درون لیست قرار دهیم
            IF ISNULL(@IsLoopOprt, '001') = '001'
            BEGIN 
               -- اگر کالا هدیه داشته باشد باید آن را اضافه کنیم
               DECLARE C$GiftProds4 CURSOR FOR
                  SELECT rp.TARF_CODE
                    FROM dbo.Service_Robot_Seller_Product_Gift pg, dbo.Service_Robot_Seller_Product p, dbo.Robot_Product rp
                   WHERE pg.TARF_CODE_DNRM = @tarfcode
                     AND pg.SSPG_CODE = p.CODE
                     AND pg.STAT = '002'
                     AND p.PROD_TYPE = '001'
                     --AND p.CRNT_NUMB_DNRM > 0
                     AND p.TARF_CODE = rp.TARF_CODE
                     AND rp.ROBO_RBID = @Rbid
                     AND rp.STAT = '002';
               
               OPEN [C$GiftProds4];
               L$GiftProds4:
               FETCH [C$GiftProds4] INTO @GiftTarfCode;
               
               IF @@FETCH_STATUS <> 0
                  GOTO L$EndGiftProds4;
               
               IF NOT EXISTS (SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @GiftTarfCode)
               BEGIN
                  SET @xTemp = (
                     SELECT @Rbid AS '@rbid',
                            @ChatId AS '@chatid',
                            @BaseUssdCode AS '@ussdcode',
                            @OrdrCode AS '@ordrcode',
                            @GiftTarfCode AS '@input',
                            '002' AS '@isloopoprt'
                       FOR XML PATH('Action'), ROOT('Cart')                    
                  );
                  EXEC dbo.SAVE_S05C_P @X = @xTemp, -- xml
                     @xRet = @xTemp OUTPUT -- xml
               END 
               ELSE
               --BEGIN
               --   SELECT @n = od.NUMB + @n
               --     FROM dbo.Order_Detail od
               --    WHERE od.ORDR_CODE = @OrdrCode
               --      AND od.TARF_CODE = @GiftTarfCode
               --END  
               
               UPDATE dbo.Order_Detail
                  SET NUMB = @n,
                      OFF_PRCT = 100,
                      OFF_TYPE = '007',
                      OFF_KIND = '003'
                WHERE ORDR_CODE = @OrdrCode
                  AND TARF_CODE = @GiftTarfCode;
                  
               -- 1399/05/03
               -- بروزرسانی موجودی جدول کالاها	                  
               UPDATE p
                  SET p.CRNT_NUMB_DNRM = p.WREH_INVR_NUMB - (p.SALE_NUMB_DNRM + (p.SALE_CART_NUMB_DNRM/* - od.NUMB*/))
                 FROM dbo.Service_Robot_Seller_Product p, dbo.Order_Detail od
                WHERE p.TARF_CODE = @GiftTarfCode
                  AND p.TARF_CODE = od.TARF_CODE
                  AND od.ORDR_CODE = @OrdrCode
                  AND p.PROD_TYPE = '002';

               GOTO L$GiftProds4;
               L$EndGiftProds4:
               CLOSE [C$GiftProds4];
               DEALLOCATE [C$GiftProds4];
            END
         END 
         -- اطلاعات دوره جدید ثبت شد
         SET @TypeCode = '001'
	   END
	   ELSE IF @OrdrType = '013' /* افزایش مبلغ کیف پول اعتباری */
	   BEGIN
	      -- اگر درخواست تازه ثبت شده باشد ردیف با مبلغ انتخابی را درج میکنیم در غیر اینصورت بروزرسانی مبلغ را انجام میدهیم.
	      MERGE dbo.Order_Detail T
	      USING (SELECT @OrdrCode AS ORDR_CODE) S
	      ON (t.ORDR_CODE = s.ORDR_CODE)
	      WHEN NOT MATCHED THEN 
	         INSERT (ORDR_CODE, ELMN_TYPE, EXPN_PRIC, NUMB, ORDR_DESC          , RQTP_CODE_DNRM, TARF_DATE)
	         VALUES (@OrdrCode, '001'    , @tarfcode, 1   , N'افزایش مبلغ کیف پول اعتباری', '020'         , GETDATE())
	      WHEN MATCHED THEN 
	         UPDATE SET
	            T.EXPN_PRIC += @tarfcode;
	      
	      SET @TypeCode = '011';
	      GOTO L$ShowResult;
	   END 
	   ELSE IF @OrdrType = '015' /* افزایش مبلغ کیف پول نقدینگی */
	   BEGIN
	      -- اگر درخواست تازه ثبت شده باشد ردیف با مبلغ انتخابی را درج میکنیم در غیر اینصورت بروزرسانی مبلغ را انجام میدهیم.
	      MERGE dbo.Order_Detail T
	      USING (SELECT @OrdrCode AS ORDR_CODE) S
	      ON (t.ORDR_CODE = s.ORDR_CODE)
	      WHEN NOT MATCHED THEN 
	         INSERT (ORDR_CODE, ELMN_TYPE, EXPN_PRIC, NUMB, ORDR_DESC          , RQTP_CODE_DNRM, TARF_DATE)
	         VALUES (@OrdrCode, '001'    , @tarfcode, 1   , N'افزایش مبلغ کیف پول نقدینگی', '020'         , GETDATE())
	      WHEN MATCHED THEN 
	         UPDATE SET
	            T.EXPN_PRIC += @tarfcode;
	      
	      SET @TypeCode = '010';
	      GOTO L$ShowResult;
	   END 
	END 
	
	-- بررسی آیا لیست ارسالی باز هم داده ای برای پردازش دارد یا خیر
	IF LEN(@FrstStepCmnd) > 0
	   GOTO L$Loop$NextItem;
	
   -- در آخر ستون های مربوط به جدول درخواست به ترتیب باید بروزرسانی شود
	-- Expn_Amnt, Extr_Prct, Dscn_Amnt_Dnrm, Pymt_Amnt_Dnrm, Cost_Amnt_Dnrm
	L$ShowResult:

   -- 1399/06/07 * گزینه ای باید اضافه گردد در مورد سیستم محاسبه هزینه پله کانی
   IF @OrdrType = '004' /* درخواست ثبت سفارش */ AND EXISTS ( SELECT * FROM dbo.Order_Detail od, dbo.Robot_Product_StepPrice rps WHERE od.ORDR_CODE = @OrdrCode AND rps.TARF_CODE_DNRM = od.TARF_CODE AND rps.STAT = '002')
   BEGIN
      -- در این قیمت باید بررسی کنید که بر اساس تعداد کالا ها باید مبلغ فروش تغییر کند یا اینکه بر اساس تعداد حجم فروش مبلغ فروش کالا در نظر رفته شود
      -- ابتدا بر اساس تعداد کالا قیمت بروزرسانی میشود      
      UPDATE od
         SET od.EXPN_PRIC = (
                              SELECT a.EXPN_PRIC
                                FROM dbo.Robot_Product_StepPrice a
                               WHERE a.TARF_CODE_DNRM = od.TARF_CODE
                                 AND a.STEP_TYPE = '001' -- محاسبه بر اساس تعداد محصول و تغییر نرخ فروش
                                 AND a.RWNO = (
                                     SELECT MAX(b.RWNO)
                                       FROM dbo.Robot_Product_StepPrice b
                                      WHERE b.TARF_CODE_DNRM = a.TARF_CODE_DNRM
                                        AND b.STEP_TYPE = '001' -- محاسبه بر اساس تعداد محصول و تغییر نرخ فروش
                                        AND b.TARF_CODE_QNTY <= od.NUMB
                                     )
                            )
            ,od.EXTR_PRCT = (
                              SELECT a.EXPN_PRIC
                                FROM dbo.Robot_Product_StepPrice a
                               WHERE a.TARF_CODE_DNRM = od.TARF_CODE
                                 AND a.STEP_TYPE = '001' -- محاسبه بر اساس تعداد محصول و تغییر نرخ فروش
                                 AND a.RWNO = (
                                     SELECT MAX(b.RWNO)
                                       FROM dbo.Robot_Product_StepPrice b
                                      WHERE b.TARF_CODE_DNRM = a.TARF_CODE_DNRM
                                        AND b.STEP_TYPE = '001' -- محاسبه بر اساس تعداد محصول و تغییر نرخ فروش
                                        AND b.TARF_CODE_QNTY <= od.NUMB
                                     )
                            ) * @TaxPrct / 100
            ,od.PRFT_PRIC_DNRM = 
                            (
                              SELECT a.EXPN_PRIC
                                FROM dbo.Robot_Product_StepPrice a
                               WHERE a.TARF_CODE_DNRM = od.TARF_CODE
                                 AND a.STEP_TYPE = '001' -- محاسبه بر اساس تعداد محصول و تغییر نرخ فروش
                                 AND a.RWNO = (
                                     SELECT MAX(b.RWNO)
                                       FROM dbo.Robot_Product_StepPrice b
                                      WHERE b.TARF_CODE_DNRM = a.TARF_CODE_DNRM
                                        AND b.STEP_TYPE = '001' -- محاسبه بر اساس تعداد محصول و تغییر نرخ فروش
                                        AND b.TARF_CODE_QNTY <= od.NUMB
                                     )
                            ) - od.BUY_PRIC_DNRM
        FROM dbo.Order_Detail od
       WHERE od.ORDR_CODE = @OrdrCode
         AND EXISTS (
               SELECT *
                 FROM dbo.Robot_Product_StepPrice a
                WHERE a.TARF_CODE_DNRM = od.TARF_CODE
                  AND a.STEP_TYPE = '001' -- محاسبه بر اساس تعداد محصول و تغییر نرخ فروش
                  AND a.TARF_CODE_QNTY <= od.NUMB
             );
   END;
	
	--1399/08/15 * محاسبه تخفیف ویژه همکاران فروش 
	--IF EXISTS (
	--   SELECT *
	--     FROM dbo.Service_Robot_Discount_Card dc
	--    WHERE dc.SRBT_ROBO_RBID = @Rbid
	--      AND dc.CHAT_ID = @ChatId
	--      AND dc.OFF_TYPE = '008' /* تخفیف عادی همکاران فروش */ 
	--      AND dc.OFF_KIND = '004'
	--      AND dc.VALD_TYPE = '002'
	--)
	--BEGIN
	--   SET @xTemp = (
	--       SELECT @Rbid AS '@rbid',
	--              @OrdrCode AS '@ordrcode',
	--              dc.DCID AS '@dcid'
	--         FROM dbo.Service_Robot_Discount_Card dc
	--        WHERE dc.SRBT_ROBO_RBID = @Rbid
	--          AND dc.CHAT_ID = @ChatId
	--          AND dc.OFF_TYPE = '008' /* تخفیف عادی همکاران فروش */ 
	--          AND dc.OFF_KIND = '004'
	--          AND dc.VALD_TYPE = '002'
	--          FOR XML PATH('Service_Robot_Discount_Card')
	--   );
	   
	--   EXEC dbo.SAVE_DSCT_P @X = @xTemp, @XRet = @xTemp OUTPUT;
	--END 
	
	UPDATE o
	   SET o.Expn_Amnt = (SELECT SUM(od.EXPN_PRIC * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	      ,o.EXTR_PRCT = (SELECT SUM(od.EXTR_PRCT * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	      ,o.PYMT_AMNT_DNRM = (SELECT SUM(os.AMNT) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.code AND os.AMNT_TYPE IN ('001', '005') AND os.CONF_STAT = '002')
	      ,o.DSCN_AMNT_DNRM = (SELECT SUM(((od.EXPN_PRIC + od.EXTR_PRCT) * od.NUMB) * ISNULL(od.OFF_PRCT, 0) / 100 ) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE) + 
	                          (SELECT ISNULL(SUM(os.AMNT), 0) FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '002' /* تخفیفات سفارش */)
	      ,o.AMNT_TYPE = @AmntType
	      --**##,o.DELV_TIME_DNRM = (SELECT MAX(ISNULL(od.DELV_TIME_DNRM, 0)) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	  FROM dbo.[Order] o
	 WHERE o.CODE = @OrdrCode;	
   
   -- 1399/10/26
   L$ShowMessage:
   
	IF @count = 1 AND ISNULL(@OrdrCode , 0) != 0
	   SET @xRet = (
	      SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                @OrdrCode AS '@ordrcode',
                N'🛍 بررسی موجودی کالای مورد نظر شما در فاکتور' + CHAR(10) + 
                N'📋 صورتحساب شما' + CHAR(10) +
                N'👈 فاکتور شما *' + CAST(@OrdrCode AS NVARCHAR(30)) + N'* [ کد سیستم ] *' + CAST(@OrdrTypeNumb AS VARCHAR(30)) + ' - ' + @OrdrType + N'*' + CHAR(10) + 
                N'📦 [ *' + @tarfcode + N'* ] • *' + rp.TARF_TEXT_DNRM + N'*' + CHAR(10) + 
                N'🔢 *' + ISNULL((SELECT CAST(od.NUMB AS NVARCHAR(10)) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @tarfcode), '0') + N'* [ *' + rp.UNIT_DESC_DNRM + N'* ]' + CHAR(10) + 
                (SELECT N'💰 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.EXPN_PRIC), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND od.TARF_CODE = @tarfcode) + CHAR(10)                
                --N'👈 *در صورت نمایش سبد خرید دکمه 📑 نمایش سبد خرید را در منوهای پایین فشار دهید*'
           FROM dbo.Robot_Product rp
          WHERE rp.ROBO_RBID = @Rbid
            AND rp.TARF_CODE = @tarfcode
	     FOR XML PATH('Message'), ROOT('Result')
	   );
	ELSE IF @TypeCode = '008' -- Show Shipping
	   SET @xRet = (
	      SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                @OrdrCode AS '@ordrcode',
                CASE @TypeCode
                     WHEN '008' THEN N'🛍 بسته های سفارش شما'
                END + CHAR(10) + CHAR(10) + 
                N'📋  صورتحساب شما' + CHAR(10) + 
                N'👈  شماره فاکتور *' + CAST(@OrdrCode AS NVARCHAR(30)) + N'* [ کد سیستم ] *' + CAST(@OrdrTypeNumb AS VARCHAR(30)) + ' - ' + @OrdrType + N'*' + CHAR(10) + CHAR(10) + 
                (
                   SELECT N'📦 *' + od.TARF_CODE + N'* ••• ' + od.ORDR_DESC + CHAR(10) + 
                          CASE DATEDIFF(DAY, od.DELV_TIME_DNRM, GETDATE()) WHEN 0 THEN '' ELSE N'🛠 [ تعداد روز تحویل ] *' + CAST(DATEDIFF(DAY, od.DELV_TIME_DNRM, GETDATE()) AS VARCHAR(10)) + N'* روز' + CHAR(10) END +
                          N'🔢 [تعداد] *' + CAST(od.NUMB AS NVARCHAR(10)) + N'* [ *' + CASE WHEN od.RQTP_CODE_DNRM IN ( '001', '009' ) THEN N'دوره' ELSE N'عدد' END + N'* ]'+ CHAR(10) + CHAR(10) 
                     FROM dbo.Order_Detail od
                    WHERE ORDR_CODE = @OrdrCode
                  FOR XML PATH('')
                ) + 
                CASE ISNULL(o.DELV_TIME_DNRM, 0) WHEN 0 THEN '' ELSE N'📦 [ تعداد روز تحویل سفارش شما ] *' + CAST(o.DELV_TIME_DNRM AS VARCHAR(30)) + N'* روز' + CHAR(10) END 
           FROM dbo.[Order] o
          WHERE o.CODE = @OrdrCode
            FOR XML PATH('Message'), ROOT('Result')
	   )
	ELSE IF @TypeCode = '009' -- Show Final Order
	   SET @xRet = (
	       SELECT 'successful' AS '@rsltdesc',
                 '002' AS '@rsltcode',
                 o.CODE AS '@ordrcode', 
	              N'☺️🖐 از پرداخت شما متشکریم' + CHAR(10) + 
	              N'💵 شرح سند : پرداخت صورتحساب ' + CHAR(10) + 
	              N'👈 [ شماره فاکتور ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'* [ کد سیستم ] *' + CAST(@OrdrTypeNumb AS VARCHAR(30)) + ' - ' + @OrdrType + N'*' + CHAR(10) + 
	              N'💵 [ مبلغ قابل پرداخت فاکتور ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
	              CASE ISNULL(o.DSCN_AMNT_DNRM, 0) WHEN 0 THEN '' ELSE N'🤑 [ تخفیف و سود شما ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DSCN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) END +
	              N'🗓 [ تاریخ و ساعت ایجاد فاکتور ] : ' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
	              N'🗓 [ تاریخ و ساعت پرداخت فاکتور ] : ' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
	              N'📑 [ شرح پرداخت شما ] : ' + CHAR(10) + 
	              (
	               SELECT N'◀️ *' + a.DOMN_DESC + N'* ' + 
	                      N'📅 *' + dbo.GET_MTOS_U(ISNULL(os.CONF_DATE, GETDATE())) + N'* ' + 
                         N'💰 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' +
                         CASE LEN(os.TXID) WHEN 0 THEN '' ELSE N'✅ *' + os.TXID + N'*' END + CHAR(10)
	                 FROM dbo.Order_State os, dbo.[D$AMTP] a
	                WHERE os.ORDR_CODE = o.CODE
	                  AND os.AMNT_TYPE IN ('001', '002', '005')
	                  AND os.CONF_STAT = '002'
	                  AND os.AMNT_TYPE = a.VALU
	                ORDER BY os.CRET_DATE
	                  FOR XML PATH('')
	              ) + CHAR(10) + 
	              N'🔔 بعد از آماده شدن سفارش از طریق *سامانه* به شما *اطلاع رسانی* میشود' + CHAR(10) + CHAR(10)	                   
	        FROM dbo.[Order] o, dbo.[D$AMUT] au
	       WHERE o.CODE = @OrdrCode
	         AND o.AMNT_TYPE = au.VALU
	     FOR XML PATH('Message'), ROOT('Result')
	   );	   
	ELSE IF @TypeCode IN ( '010', '011' ) -- افزایش مبلغ کیف پول
	   SET @xRet = (
	      SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                o.CODE AS '@ordrcode', 
                N'💎 درخواست افزایش مبلغ کیف پول' + CASE @TypeCode WHEN '010' THEN N' *نقدینگی* ' WHEN '011' THEN N' *اعتباری* ' END + CHAR(10) + 
                N'استفاده از کیف پول جهت سرعت بخشیدن به فرآیند خرید شما می باشد. ' + CHAR(10) + CHAR(10) +
                N'👈 برای افزایش مبلغ کیف پول خود می توانید *گزینه های موجود* را انتخاب کرده و یا آنها را با هم *جمع* بزنید. ' + CHAR(10) + CHAR(10) +
                
                N'💵 مبلغ افزایش کیف پول شما *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DEBT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + 
                --N'می باشد لطفا جهت تکمیل فرآیند افزایش موجودی دکمه *💳 پرداخت* را انتخاب کنید'
                CASE o.DEBT_DNRM 
                     WHEN 0 THEN ''
                     ELSE --N'💵 مبلغ افزایش کیف پول شما *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DEBT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + 
                          N'می باشد لطفا جهت تکمیل فرآیند افزایش موجودی، دکمه *💳 پرداخت* را انتخاب کنید'
                END 
	        FROM dbo.[Order] o
	       WHERE o.CODE = @OrdrCode
	         FOR XML PATH('Message'), ROOT('Result')
	   );
	ELSE IF @TypeCode = '012' -- عدم ثبت درخواست و نمایش خطا به مشتری
	   SET @xRet = (
	      SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                o.CODE AS '@ordrcode', 
                N'💎 متاسفانه در ثبت سبد خرید شما مشکل داخل سیستم بوجود آماده که پیام خطا برای مدیر فروشگاه ارسال شده لطفا تا برطرف شدن مشکل صبر کندی'
	        FROM dbo.[Order] o
	       WHERE o.CODE = @OrdrCode
	         FOR XML PATH('Message'), ROOT('Result')
	   );
	ELSE IF EXISTS(SELECT * FROM dbo.Order_Detail WHERE ORDR_CODE = @OrdrCode)
	   SELECT @xRet = (
       SELECT 'successful' AS '@rsltdesc',
              '002' AS '@rsltcode',
              @OrdrCode AS '@ordrcode',
              CASE @TypeCode 
                   WHEN '001' THEN N'➕ اطلاعات مورد نظر شما با موفقیت در سبد خرید قرار گرفت'
                   WHEN '002' THEN N'❌ گزینه مورد نظر شما از سبد خرید حذف گردید'
                   WHEN '003' THEN N'#️⃣ اطلاعات مورد نظر شما در سبد خرید ویرایش گردید'
                   WHEN '004' THEN N'🛍 درخواست نمایش سبد خرید شما'
                   WHEN '006' THEN N'🛍 درخواست فاکتور خرید شما'
              END + CHAR(10) + CHAR(10) + 
              --N'📋  فاکتور' + CHAR(10) + 
              N'📝  فاکتور به شماره *' + CAST(@OrdrCode AS NVARCHAR(30)) + N'* [ کد سیستم ] *' + CAST(@OrdrTypeNumb AS VARCHAR(30)) + ' - ' + @OrdrType + N'*' + CHAR(10) + CHAR(10) + 
              N'*اقلام فاکتور*' + CHAR(10) + 
              (
                 SELECT N'◀️ *' + od.ORDR_DESC + N'* ( کد محصول : ' + od.TARF_CODE + N' )' +  CHAR(10) + 
                        N'💰 [ مبلغ واحد ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.EXPN_PRIC), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + 
                        CASE WHEN ISNULL(od.OFF_PRCT, 0) > 0 THEN 
                             N'••• 🤑 [ تخفیف ] *' + CAST(od.OFF_PRCT AS NVARCHAR(3)) + N'%* ' + 
                             '' + CHAR(10)--**N' =  *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.DSCN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + CHAR(10)
                             ELSE N' '
                        END +
                        CASE WHEN ISNULL(od.TAX_PRCT, 0) != 0 THEN N'🇮🇷 [ ارزش افزوده ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.EXTR_PRCT), 1), '.00', '') + + N'* [ *' + @AmntTypeDesc + N'* ] ' + N'🔢 [تعداد] *' + CAST(od.NUMB AS NVARCHAR(10)) + N'* [ *دوره* ]'+ CHAR(10) + CHAR(10) 
                             ELSE N' [ تعداد ] *' + CAST(od.NUMB AS NVARCHAR(10)) + N'* [ *' + CASE WHEN od.RQTP_CODE_DNRM IN ( '001', '009' ) THEN N'دوره' ELSE N'عدد' END + N'* ]'--**+ CHAR(10) + CHAR(10) 
                        END + CHAR(10) + /*dbo.STR_COPY_U('- + -', 15) +*/ CHAR(10)
                   FROM dbo.Order_Detail od
                  WHERE ORDR_CODE = @OrdrCode
                FOR XML PATH('')
              ) + 
              (
                SELECT CASE WHEN ISNULL(o.EXTR_PRCT, 0) != 0 THEN 
                              N'🛍 [ جمع مبلغ صورتحساب ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
                              N'🇮🇷 [ ارزش افزوده ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXTR_PRCT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
                              CASE WHEN ISNULL(o.TXFE_AMNT_DNRM, 0) != 0 THEN 
                                     ''--**N'👈 [ کارمزد خدمات غیرحضوری ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.TXFE_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) 
                                   ELSE
                                     N' '
                              END +
                              CASE WHEN ISNULL(o.DSCN_AMNT_DNRM, 0) > 0 THEN                                    
                                   --**N'🤑 [ تخفیف و سود شما ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DSCN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + CHAR(10)
                                   ''
                                   ELSE N' '
                              END +
                              N'💵 [ مبلغ نهایی ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' 
                            ELSE 	                                 
                              CASE WHEN ISNULL(o.TXFE_AMNT_DNRM, 0) != 0 THEN 
                                     N'🛍 [ جمع مبلغ صورتحساب ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
                                     ''--**N'👈 [ کارمزد خدمات غیرحضوری ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.TXFE_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) 
                                   ELSE
                                     N' '
                              END + 
                              CASE WHEN ISNULL(o.DSCN_AMNT_DNRM, 0) > 0 THEN                                    
                                   --**N'🤑 [ تخفیف و سود شما ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DSCN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + CHAR(10)
                                   ''
                                   ELSE N' '
                              END +
                              N'💵 [ مبلغ نهایی با کسر تخفیف ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' 
                       END + CHAR(10) +
                       CASE ISNULL(o.DEBT_DNRM, 0)
                            WHEN 0 THEN CHAR(10) + N'✅ *تسویه حساب کامل*' + CHAR(10) + N'👈 جهت اتمام فرآیند در *💳 نحوه پرداخت* *⚡️ پایان سفارش* را انتخاب کنید'
                            ELSE CASE WHEN o.DEBT_DNRM > 0 AND ISNULL(o.PYMT_AMNT_DNRM, 0) = 0 THEN N'💰 [ مبلغ قابل پرداخت ] *' WHEN o.DEBT_DNRM > 0 AND ISNULL(o.PYMT_AMNT_DNRM, 0) > 0 THEN N'💰 [ مبلغ باقیمانده ] *' END + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DEBT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) +
                                 CASE ISNULL(o.PYMT_AMNT_DNRM, 0)
                                      WHEN 0 THEN ''
                                      ELSE N'📑 [ مبلغ پرداخت شده ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.PYMT_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10)
                                 END 
                       END + 
                       CASE -- اگر فروشگاه مدت زمان خرید برای مشتریان گذاشته باشد 
                            WHEN ISNULL(@OrdrExprStat, '000') = '002' THEN N'⏱️ [ زمان باقیمانده جهت خرید ] *' + CAST(DATEDIFF(MINUTE, GETDATE(), DATEADD(MINUTE, @OrdrExprTime, o.STRT_DATE)) AS varchar(2)) + N'* [ دقیقه ]' + CHAR(10)
                            ELSE N''
                       END + 
                       CASE -- بررسی اینکه مشخص شده باشد نحوه ارسال بسته به چه صورتی میباشد و اگر سقف خرید وجود دارد برای ارسال رایگان اوکی شده یا خیر
                            WHEN ISNULL(o.HOW_SHIP, '000') = '002' AND @FreeShipInctAmnt > 0 THEN 
                                 CASE 
                                     WHEN @FreeShipInctAmnt > o.SUM_EXPN_AMNT_DNRM THEN CHAR(10) + N'🏍️ سفارش های بالا *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @FreeShipInctAmnt), 1), '.00', '') +  N'* [ *' + au.DOMN_DESC + N'* ] به صورت 🤩 *رایگان ارسال* میگردد. ' + N'با اضافه کردن مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @FreeShipInctAmnt - o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') +  N'* [ *' + au.DOMN_DESC + N'* ] به سبد خرید خود، ارسال سفارش خود را ✅ *رایگان* کنید' + CHAR(10)
                                     ELSE CHAR(10) + N'👈 سفارش شما به صورت ✅ *رایگان ارسال* میگردد' + CHAR(10)
                                 END
                            WHEN ISNULL(o.HOW_SHIP, '000') = '003' AND @FreeShipOtctAmnt > 0 THEN 
                                 CASE
                                    WHEN @FreeShipOtctAmnt > o.SUM_EXPN_AMNT_DNRM THEN CHAR(10) + N'🏍️ سفارش های بالا *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @FreeShipOtctAmnt), 1), '.00', '') +  N'* [ *' + au.DOMN_DESC + N'* ] به صورت 🤩 *رایگان ارسال* میگردد. ' + N'با اضافه کردن مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @FreeShipOtctAmnt - o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') +  N'* [ *' + au.DOMN_DESC + N'* ] به سبد خرید خود، ارسال سفارش خود را ✅ *رایگان* کنید' + CHAR(10)
                                    ELSE CHAR(10) + N'👈 سفارش شما به صورت ✅ *رایگان ارسال* میگردد' + CHAR(10)
                                 END
                            ELSE N' '
                       END 
                  FROM dbo.[Order] o, dbo.[D$AMUT] au
                 WHERE o.CODE = @OrdrCode
                   AND o.AMNT_TYPE = au.VALU
              ) + CHAR(10) + 
              CASE 
                  WHEN EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001', '002', '005')) THEN dbo.STR_COPY_U('•', 60) + CHAR(10) 
                  ELSE '' 
              END +
              ISNULL(
                 (
                   SELECT N'👈 [ ' + a.DOMN_DESC + N' ] ' + 
                          CASE os.AMNT_TYPE
                               WHEN '001' /* درآمد */ THEN N'💰 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM(os.AMNT)), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] *رسید یا پرداخت با کارت اعتباری یا کیف پول*' 
                               WHEN '002' /* تخفیف */ THEN N'🤑 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM(os.AMNT)), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] *تخفیف بن کارت*' 
                               WHEN '005' /* رسید پرداخت */ THEN N'📋 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM(ISNULL(os.AMNT, 0))), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ]' 
                          END + CHAR(10)
                     FROM dbo.[Order]o, dbo.Order_State os, dbo.[D$AMTP] a, dbo.[D$AMUT] au
                    WHERE os.ORDR_CODE = @OrdrCode
                      AND o.CODE = os.ORDR_CODE
                      AND os.AMNT_TYPE = a.VALU
                      AND o.AMNT_TYPE = au.VALU
                    GROUP BY os.AMNT_TYPE, a.DOMN_DESC, au.DOMN_DESC
                      FOR XML PATH('')
                 ) + CHAR(10) 
              , '' ) +
              (
                 CASE 
                   WHEN (SELECT COUNT(os.CODE) FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ( '001', '005' ) AND os.CONF_STAT = '002') = 0 THEN (
                    ''  
                    --CASE 
                    -- WHEN @typecode = '004' THEN 
                    --    (SELECT N'ℹ️  لطفا جهت پرداخت صورتحساب دکمه *"💳 نحوه پرداخت"* را فشار دهید.' + N' توجه داشته باشید که کارمزد *خدمات غیرحضوری* به مبلغ * ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.TXFE_AMNT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] میباشد'
                    --      FROM dbo.[Order] o
                    --     WHERE o.CODE = @OrdrCode)                        
                    -- ELSE N'👈  لطفا جهت پرداخت صورتحساب دکمه *"🔺 بازگشت"* را فشار دهید و بعد دکمه *"💳 نحوه پرداخت"* را فشار دهید'	                 
                    --END 
                   )
                   ELSE                   
                   (
                     SELECT N'📅 *' + dbo.GET_MTOS_U(ISNULL(os.CONF_DATE, GETDATE())) + N'* ' + 
                            N'💰 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' +
                            CASE LEN(os.TXID) WHEN 0 THEN '' ELSE N'✅ *' + os.TXID + N'*' END + CHAR(10)
                       FROM dbo.Order_State os, dbo.[Order] o, dbo.[D$AMUT] au
                      WHERE os.ORDR_CODE = @OrdrCode
                        AND os.ORDR_CODE = o.CODE
                        AND o.AMNT_TYPE = au.VALU
                        AND os.AMNT_TYPE IN ('001', '005')
                        AND os.CONF_STAT = '002'
                        FOR XML PATH('')
                   )
                 END + 
                 (SELECT CASE o.HOW_SHIP 
                              WHEN '000' THEN '' 
                              WHEN '001' THEN N'📢 بسته سفارش *شما* 🏃 *درب فروشگاه تحویل* داده میشود' + CHAR(10) +
                                              N'📍 _' + o.SORC_POST_ADRS + N'_' + CHAR(10) + 
                                              N'📲 _' + o.SORC_CELL_PHON + N'_' + CHAR(10) + 
                                              N'☎️ _' + o.SORC_TELL_PHON + N'_' + CHAR(10) +
                                              N'🔔 بعد از آماده شدن سفارش از *طریق سامانه* به *شما اطلاع رسانی* میشود' + CHAR(10) + CHAR(10)
                              WHEN '002' THEN N'📢 بسته سفارش شما به *آدرس انتخاب شده* 🏍 ارسال میگردد' + CHAR(10) +
                                              N'📍 _' + o.SERV_ADRS + N'_' + CHAR(10) + CHAR(10)
                              WHEN '003' THEN N'📢 بسته سفارش شما به *آدرس انتخاب شده* 🚚 ارسال میگردد' + CHAR(10) +
                                              N'📍 _' + o.SERV_ADRS + N'_' + CHAR(10) + CHAR(10)
                         END +
                         CASE o.HOW_SHIP 
                              WHEN '000' THEN N'ℹ️  لطفا جهت ارسال سفارش دکمه *"🚚 نحوه ارسال"* را فشار دهید.'
                              ELSE  N'ℹ️  لطفا جهت پرداخت صورتحساب دکمه *"💳 نحوه پرداخت"* را فشار دهید.' + CASE ISNULL(o.TXFE_AMNT_DNRM, 0) WHEN 0 THEN N'' ELSE N' توجه داشته باشید که کارمزد *خدمات غیرحضوری* به مبلغ * ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.TXFE_AMNT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] میباشد' END 
                         END 
                    FROM dbo.[Order] o
                   WHERE o.CODE = @OrdrCode)
              ) 
          FOR XML PATH('Message'), ROOT('Result')   	
	   )
	ELSE
	   SELECT @xRet = (
	      SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                0 AS '@ordrcode',
                N'⚠️ سبد خرید شما خالی می باشد'
	     FOR XML PATH('Message'), ROOT('Result')	     
	   );
	
	L$End:
	COMMIT TRAN [T$SAVE_S05C_P];
	END TRY
	BEGIN CATCH 
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
	   PRINT @ErorMesg;
	   ROLLBACK TRAN [T$SAVE_S05C_P];
	END CATCH;
END
GO
