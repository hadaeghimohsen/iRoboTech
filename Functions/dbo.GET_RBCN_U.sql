SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_RBCN_U]
(
	@X XML
)
RETURNS VARCHAR(16)
AS
BEGIN
	DECLARE @Rbid BIGINT = @X.query('//Order').value('(Order/@rbid)[1]','BIGINT')
	       ,@OrdrType VARCHAR(3) = @X.query('//Order').value('(Order/@type)[1]','VARCHAR(3)')
	       ,@OrdrCode BIGINT = @X.query('//Order').value('(Order/@code)[1]','BIGINT')
	       ,@CardNumb VARCHAR(16) = @X.query('//Order').value('(Order/@cardnumb)[1]','varchar(16)')
	       ,@TOrdrCode BIGINT;
   
   -- اگر درخواستی خودش کارت مقصد را انتخاب کند ما دیگر تغییری درآن نمیدهیم
   IF @CardNumb IS NOT NULL AND LEN(@CardNumb) = 16 RETURN @CardNumb
	
	-- حساب کارفرما
	IF @OrdrType IN ('004', '015')
	BEGIN
	   SELECT TOP 1 @CardNumb = CARD_NUMB
	     FROM dbo.Robot_Card_Bank_Account
	    WHERE ROBO_RBID = @Rbid
	      AND ACNT_TYPE = '002' -- حساب های کارفرما یا فروشگاه
         AND ORDR_TYPE = @OrdrType
	      AND ACNT_STAT = '002' /* حساب های فعال */;
	END
	-- حساب سفیران ارسال بسته
	ELSE IF @OrdrType IN ( '023' ) 
	BEGIN
	   -- بدست آوردن شماره درخواست پیک
	   SELECT @TOrdrCode = o.ORDR_CODE
	     FROM dbo.[Order] o
	    WHERE o.CODE = @OrdrCode;
	   
	   SELECT TOP 1 @CardNumb = a.CARD_NUMB
	     FROM dbo.Robot_Card_Bank_Account a, dbo.Service_Robot_Card_Bank b, dbo.[Order] o
	    WHERE b.SRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO
	      AND b.SRBT_ROBO_RBID = o.SRBT_ROBO_RBID
	      AND b.CHAT_ID = o.CHAT_ID
	      AND o.CODE = @TOrdrCode
	      AND a.CODE = b.RCBA_CODE
	      AND a.ORDR_TYPE = @OrdrType /* درآمدهای مربوط به حق الزحمه پیک */
	      AND a.ACNT_TYPE = '003' /* حساب های متفرقه */
	      AND a.ACNT_STAT = '002'; 
	END 
	-- حساب شرکت انار
	ELSE IF @OrdrType IN ('013', '014', '016')
	BEGIN
	   DECLARE @RobotCardBankAccount TABLE (Code BIGINT, Card_Numb VARCHAR(16), Ordr_Type VARCHAR(3));
	   
	   INSERT INTO @RobotCardBankAccount (Code ,Card_Numb ,Ordr_Type)
	   SELECT CODE, CARD_NUMB, ORDR_TYPE
        FROM dbo.Robot_Card_Bank_Account
       WHERE ROBO_RBID = @Rbid
         AND ACNT_TYPE = '001'
         AND ACNT_STAT = '002';
	         
	   IF (SELECT COUNT(code) FROM @RobotCardBankAccount) = 1
	      SELECT @CardNumb = Card_Numb
	        FROM @RobotCardBankAccount;
	   ELSE IF (SELECT COUNT(code) FROM @RobotCardBankAccount) > 1
	      SELECT TOP 1 @CardNumb = Card_Numb
	        FROM @RobotCardBankAccount
	       WHERE Ordr_Type = @OrdrType;
	END
	
	RETURN @CardNumb;
END
GO
