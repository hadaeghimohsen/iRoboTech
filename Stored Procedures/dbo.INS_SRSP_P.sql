SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_SRSP_P]
	@SRBS_CODE BIGINT,
	@RBPR_CODE BIGINT
AS
BEGIN
	BEGIN TRY
	   BEGIN TRANSACTION [T$INS_SRSP_P]
	   
	   -- Local Var
	   DECLARE @AdminChatId BIGINT ,
	           @TSrbsCode BIGINT, -- اطلاعات فروشنده مدیر فروشگاه
	           @TChatId BIGINT, -- اطلاعات مربوط به فروشنده ای که ارسال شده
	           @Rbid BIGINT;
	   
	   -- بدست آوردن شماره مدیر فروشگاه
	   SELECT @AdminChatId = sr.CHAT_ID,
	          @Rbid = sr.ROBO_RBID
	     FROM dbo.Service_Robot sr, dbo.Service_Robot_Group g, dbo.Service_Robot_Seller s
	    WHERE sr.SERV_FILE_NO = g.SRBT_SERV_FILE_NO
	      AND sr.ROBO_RBID = s.SRBT_ROBO_RBID
	      AND s.CODE = @SRBS_CODE
	      AND g.GROP_GPID = 131 -- گروه مدیریان فروشگاه
	      AND g.STAT = '002';	   
	   
	   SELECT @TSrbsCode = s.CODE
	     FROM dbo.Service_Robot_Seller s
	    WHERE s.SRBT_ROBO_RBID = @Rbid
	      AND s.CHAT_ID = @AdminChatId;
	   
	   -- بررسی اینکه کالا دست مدیر فروشگاه باشد   
	   IF EXISTS (
	      SELECT *
	        FROM dbo.Service_Robot_Seller_Product sp
	       WHERE sp.RBPR_CODE = @RBPR_CODE
	         AND sp.SRBS_CODE = @TSrbsCode -- مدیر فروشگاه
	         AND sp.CHAT_ID = @AdminChatId
	   )
	   BEGIN
	      -- بله کالا دست مدیر فروشگاه میباشد که حال میتوانید امتیاز فروش کالا را به تامین کننده دیگری واگذار کنید
	      -- حال اگر کالایی که میخواهیم به شخص دیگری بسپاریم همان مدیر فروشگاه باشد کار باید نادیده گرفته شود
	      IF @TSrbsCode = @SRBS_CODE
	      BEGIN
	         -- برای این قسمت نیازی به انجام کاری نیست چون کالا در اختیار مدیر فروشگاه میباشد و دیگر نیازی به دوباره وارد کردن ردیف برای این کالا نمی باشد
	         RETURN;
	      END 
	      
	      -- بدست آوردن اطلاعات مربوط به فروشنده جدید برای اعطای تامین کنندگی کالا مورد نظر
	      SELECT @TChatId = CHAT_ID	      
	        FROM dbo.Service_Robot_Seller
	       WHERE CODE = @SRBS_CODE;
	      
	      -- در این قسمت که کالا را میخواهیم به تامین کننده دیگری قرار دهیم فقط کافیست که اطلاعات را بروزرسانی کنیم
	      UPDATE dbo.Service_Robot_Seller_Product 
	         SET SRBS_CODE = @SRBS_CODE,
	             CHAT_ID = @TChatId
	       WHERE RBPR_CODE = @RBPR_CODE;
	   END
	   ELSE
	   BEGIN
	      RAISERROR(N'کالای مورد نظر شما در دست تامین کننده دیگری میباشد، لطفا ابتدا آن کالا را از گروه تامین کننده خارج کنید و دوباره عملیات را انجام دهید', 16, 1);
	   END 
	   
	   COMMIT TRANSACTION [T$INS_SRSP_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
	   ROLLBACK TRANSACTION [T$INS_SRSP_P]
	END CATCH
END
GO
