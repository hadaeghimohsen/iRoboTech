SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_SRSP_P]
	@Code BIGINT
AS
BEGIN
	BEGIN TRY
	   BEGIN TRANSACTION [T$DEL_SRSP_P]
	   
	   -- Local Var
	   DECLARE @AdminChatId BIGINT ,
	           @TSrbsCode BIGINT, -- اطلاعات فروشنده مدیر فروشگاه
	           @TChatId BIGINT, -- اطلاعات مربوط به فروشنده ای که ارسال شده
	           @Rbid BIGINT;
	   
	   -- بدست آوردن شماره مدیر فروشگاه
	   SELECT @AdminChatId = sr.CHAT_ID,
	          @Rbid = sr.ROBO_RBID
	     FROM dbo.Service_Robot sr, dbo.Service_Robot_Group g, dbo.Service_Robot_Seller_Product sp, dbo.Service_Robot_Seller s
	    WHERE sr.SERV_FILE_NO = g.SRBT_SERV_FILE_NO
	      AND sr.ROBO_RBID = s.SRBT_ROBO_RBID
	      AND sp.SRBS_CODE = s.CODE
	      AND sp.CODE = @CODE
	      AND g.GROP_GPID = 131 -- گروه مدیریان فروشگاه
	      AND g.STAT = '002';	   
	   
	   SELECT @TSrbsCode = s.CODE
	     FROM dbo.Service_Robot_Seller s
	    WHERE s.SRBT_ROBO_RBID = @Rbid
	      AND s.CHAT_ID = @AdminChatId;
	   
	   -- بررسی اینکه کالا دست مدیر فروشگاه باشد   
	   IF NOT EXISTS (
	      SELECT *
	        FROM dbo.Service_Robot_Seller_Product sp
	       WHERE sp.CODE = @Code
	         AND sp.CHAT_ID = @AdminChatId
	   )
	   BEGIN
	      -- بله کالا دست تامین کننده فروشگاه میباشد که حال میتوانید امتیاز فروش کالا را از تامین کننده بگیرید	      
	      -- در این قسمت که کالا را میخواهیم به مدیر فروشگاه قرار دهیم فقط کافیست که اطلاعات را بروزرسانی کنیم
	      UPDATE dbo.Service_Robot_Seller_Product 
	         SET SRBS_CODE = @TSrbsCode,
	             CHAT_ID = @AdminChatId
	       WHERE CODE = @Code;
	   END
	   ELSE
	   BEGIN
	      RAISERROR(N'کالای مورد نظر شما در دست مدیر فروشگاه میباشد، برای حذف کالا در قسمت تعریف کالا و محصولات آن را غیر فعال کنید', 16, 1);
	   END 
	   
	   COMMIT TRANSACTION [T$DEL_SRSP_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
	   ROLLBACK TRANSACTION [T$DEL_SRSP_P]
	END CATCH
END
GO
