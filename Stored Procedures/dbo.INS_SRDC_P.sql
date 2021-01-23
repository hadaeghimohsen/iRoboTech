SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_SRDC_P]
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$INS_SRDC_P]
	   -- Init Var
	   DECLARE @ServFileNo BIGINT,
	           @Rbid BIGINT,
	           @ChatId BIGINT,
	           @OffPrct REAL,
	           @OffType VARCHAR(3),
	           @OffKind VARCHAR(3),
	           @FromAmnt BIGINT,
	           @DiscCode VARCHAR(8),
	           @MaxAmntOff BIGINT,
	           @ExprDate DATETIME;
	   
	   SELECT @ServFileNo = @x.query('//Service_Robot').value('(Service_Robot/@servfileno)[1]', 'BIGINT'),
	          @Rbid = @x.query('//Service_Robot').value('(Service_Robot/@rbid)[1]', 'BIGINT'),
	          --@ChatId = @x.query('//Service_Robot').value('(Service_Robot/@chatid)[1]', 'BIGINT'),
	          @OffPrct = @x.query('//Discount_Card').value('(Discount_Card/@offprct)[1]', 'REAL'),
	          @OffType = @x.query('//Discount_Card').value('(Discount_Card/@offtype)[1]', 'VARCHAR(3)'),
	          @OffKind = @x.query('//Discount_Card').value('(Discount_Card/@offkind)[1]', 'VARCHAR(3)'),
	          @FromAmnt = @x.query('//Discount_Card').value('(Discount_Card/@fromamnt)[1]', 'BIGINT'),
	          @DiscCode = @x.query('//Discount_Card').value('(Discount_Card/@disccode)[1]', 'VARCHAR(8)'),
	          @MaxAmntOff = @x.query('//Discount_Card').value('(Discount_Card/@maxamntoff)[1]', 'BIGINT'),
	          @ExprDate = @x.query('//Discount_Card').value('(Discount_Card/@exprdate)[1]', 'DATETIME');
	    
	    IF @OffPrct = '008' BEGIN SET @OffKind = '004'; SET @ExprDate = NULL; END
	    IF ISNULL(@OffPrct, 0) = 0 RAISERROR(N'لطفا درصد تخفیف را وارد کنید', 16, 1);
	    IF ISNULL(@DiscCode, '') = '' RAISERROR(N'لطفا شماره کد تخفیف را وارد کنید', 16, 1);
	    
	    IF @OffType = '008' AND @OffKind = '004' AND
	       EXISTS(
	         SELECT * 
	           FROM dbo.Service_Robot_Discount_Card d
	          WHERE d.SRBT_ROBO_RBID = @Rbid
	            AND d.SRBT_SERV_FILE_NO = @ServFileNo
	            AND d.OFF_TYPE = @OffType
	            AND d.OFF_KIND = @OffKind
	            AND d.VALD_TYPE = '002'
	       )
	    BEGIN
	      RAISERROR(N'کد تخفیف همکار فقط یک بار میتوانید تعریف کنید', 16, 1);	     
	    END 
	    
	    -- Local Var
	    DECLARE @XTemp XML,
	            @RsltCode VARCHAR(3),
	            @OrdrCode BIGINT,
	            @OrdrDesc NVARCHAR(MAX);
	    
	    -- کد شناسایی مشتری
	    SELECT @ChatId = sr.CHAT_ID
	      FROM dbo.Service_Robot sr
	     WHERE sr.SERV_FILE_NO = @ServFileNo
	       AND sr.ROBO_RBID = @Rbid;
	    
	    SELECT @XTemp =
       (
           SELECT 12 AS '@subsys',
                  '021' AS '@ordrtype',
                  '000' AS '@typecode',
                  @ChatID AS '@chatid',
                  @Rbid AS '@rbid',
                  0 AS '@ordrcode'
           FOR XML PATH('Action'), ROOT('Cart')
       );
       EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml

       -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
       SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)'),
              @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
	    
	    IF @RsltCode = '002' AND ISNULL(@OrdrCode, 0) != 0
	    BEGIN
	        SELECT @OrdrDesc = d.DOMN_DESC FROM dbo.[D$OFTP] d WHERE d.VALU = @OffType;
	        
	        INSERT INTO dbo.Order_Detail ( ORDR_CODE ,ELMN_TYPE ,ORDR_DESC ,OFF_PRCT ,OFF_TYPE ,OFF_KIND ,NUMB )
	        VALUES (@OrdrCode, '001', @OrdrDesc, @OffPrct, @OffType, @OffKind, 1);
	        
	        INSERT INTO dbo.Service_Robot_Discount_Card ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_CODE ,DCID ,OFF_PRCT ,OFF_TYPE ,OFF_KIND ,FROM_AMNT ,DISC_CODE ,MAX_AMNT_OFF ,EXPR_DATE ,VALD_TYPE )
	        VALUES (@ServFileNo, @Rbid, @OrdrCode, 0, @OffPrct, @OffType, @OffKind, @FromAmnt, @DiscCode, @MaxAmntOff, @ExprDate, '002');
	        
	        UPDATE dbo.[Order] 
	           SET ORDR_STAT = '004'
	         WHERE CODE = @OrdrCode;
	        
	        COMMIT TRAN [T$INS_SRDC_P];	        
	    END
	    ELSE
	      RAISERROR(N'در ثبت اطلاعات درخواست تخفیف مشکلی بوجود آماده، لطفا بررسی کنید', 16, 1);
	--COMMIT TRAN [T$INS_SRDC_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	END CATCH;
END
GO
