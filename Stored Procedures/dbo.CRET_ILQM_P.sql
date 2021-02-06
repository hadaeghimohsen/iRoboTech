SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_ILQM_P]
@X xml, @XRet xml OUTPUT
WITH EXEC AS CALLER
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$CRET_ILQM_P];
	   DECLARE @Rbid BIGINT  	             ,@CmndText VARCHAR(100)	          ,@TarfCode VARCHAR(100)       ,@UssdCode VARCHAR(250)
	          ,@ParamsText NVARCHAR(250)    ,@Chatid BIGINT        	          ,@OrdrCode BIGINT	          ,@OrdrRwno BIGINT
	          ,@RbppCode BIGINT	          ,@OdstCode BIGINT      	          ,@discdcid BIGINT	          ,@SrorCode BIGINT
	          ,@FromDate DATE   	          ,@ToDate DATE;
	   
	   SELECT @Rbid = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@rbid)[1]', 'BIGINT')
	         ,@CmndText = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@cmndtext)[1]', 'VARCHAR(100)')
	         ,@TarfCode = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@tarfcode)[1]', 'VARCHAR(100)')
	         ,@UssdCode = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@ussdcode)[1]', 'VARCHAR(250)')
	         ,@ParamsText = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@param)[1]', 'NVARCHAR(250)')
	         ,@Chatid = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@chatid)[1]', 'BIGINT')
	         ,@OrdrCode = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@ordrcode)[1]', 'BIGINT')
	         ,@OrdrRwno = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@ordrrwno)[1]', 'BIGINT')
	         ,@RbppCode = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@rbppcode)[1]', 'BIGINT')
	         ,@OdstCode = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@odstcode)[1]', 'BIGINT')
	         ,@discdcid = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@discdcid)[1]', 'BIGINT')
	         ,@SrorCode = @X.query('//RequestInLineQuery').value('(RequestInLineQuery/@srorcode)[1]', 'BIGINT');
	   
	   -- Manual Trigger : 
	   -- << Execute Trigger Before Show Main Result Function
	   -- >> Execute Trigger After Show Main Result Function
	   -- <> Execute Just Trigger and NOT Show Main Result Function
	   
	   SET @XRet = '';
	   -- local var
	   DECLARE @Numb REAL
	          ,@index INT = 1
	          ,@ConfStat VARCHAR(3)
	          ,@ConfDate DATETIME
	          ,@OrdrStat VARCHAR(3)
	          ,@TChatId BIGINT
	          ,@TCode BIGINT;
	   
	   IF @CmndText IN ('lessreguser')
	   BEGIN
	      -- Next Step #. افزودن به سبد خرید
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};reguser-$#' , '*1*0*0#') AS '@data',
	                @index AS '@order',
	                N'💾 ثبت اطلاعات کاربری' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};reguserothrcnty-$#' , '*1*0*0#') AS '@data',
	                @index AS '@order',
	                N'💾 ثبت اطلاعات کاربران اتباع خارجی' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessinfoprod', 'moreinfoprod' )
	   BEGIN
	      -- Next Step #. افزودن به سبد خرید
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'➕ افزودن به سبد خرید' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;

	      -- Next Step #. حذف کردن از سبد خرید
	      -- Dynamic
	      SELECT @Numb = od.NUMB 
           FROM dbo.[Order] o, dbo.Order_Detail od
          WHERE o.CODE = od.ORDR_CODE
            AND o.CHAT_ID = @Chatid
            AND o.SRBT_ROBO_RBID = @Rbid
            AND o.ORDR_TYPE = '004'
            AND o.ORDR_STAT = '001'
            AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE)
            AND od.TARF_CODE = @TarfCode;
	      
	      IF ISNULL(@Numb, 0) >= 1
	      BEGIN
	         -- Next Step #. وارد کردن تعداد دستی
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('!./{0};numbprodcart-{1}$del#', '*0*2#,' + @TarfCode ) AS '@data',
	                   @index AS '@order',
	                   N'✏️ ورود دستی تعداد' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END
	      -- اگر کالا درون سبد خرید مشتری برای امروز قرار گرفته باشد
	      IF ISNULL(@Numb, 0) >= 1
	      BEGIN
	         SET @X = (
               SELECT --dbo.STR_FRMT_U('./{0};delcart-{1}*del$del#>>infoprod^{1}', @UssdCode + ',' + @TarfCode) AS '@data',
                      dbo.STR_FRMT_U('./{0};delcart-{1}*del$del#', @UssdCode + ',' + @TarfCode) AS '@data',
                      @index AS '@order',
                      N'❌ حذف کردن از سبد خرید' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1; 
	         
	         IF @Numb > 1	            
	         begin
	            SET @X = (
	               SELECT --dbo.STR_FRMT_U('./{0};deccart-{1}*--$del#>>infoprod^{1}', @UssdCode + ',' + @TarfCode) AS '@data',
	                      dbo.STR_FRMT_U('./{0};deccart-{1}*--$del#', @UssdCode + ',' + @TarfCode) AS '@data',
	                      @index AS '@order',
	                      N'➖ کاهش تعداد محصول از سبد خرید' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	            SET @index += 1; 
	         END 
	      END; 	      
	      
	      IF NOT EXISTS (SELECT * FROM dbo.Service_Robot_Product_Like WHERE SRBT_ROBO_RBID = @Rbid AND CHAT_ID = @Chatid AND TARF_CODE_DNRM = @TarfCode AND STAT = '002')
	      BEGIN	      
	         --- Next Step #. افزودن به لیست علاقه مندی ها
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};likeprod-{1}$del#<>infoprod^{1}', @UssdCode + ',' + @TarfCode) AS '@data',
	                   @index AS '@order',
	                   N'❤️ افزودن به لیست علاقه مندی ها' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      ELSE
	      BEGIN
	         --- Next Step #. افزودن به لیست علاقه مندی ها
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};likeprod-{1}$del#<>infoprod^{1}', @UssdCode + ',' + @TarfCode) AS '@data',
	                   @index AS '@order',
	                   N'🖤 خارج کردن از لیست علاقه مندی ها' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      IF NOT EXISTS (SELECT * FROM dbo.Service_Robot_Product_Amazing_Notification WHERE SRBT_ROBO_RBID = @Rbid AND CHAT_ID = @Chatid AND TARF_CODE_DNRM = @TarfCode AND STAT = '002')
	      BEGIN 
	         -- Next Step #. اعلان و اطلاع رسانی شگفت انگیز
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};amzgnoti-{1}$del#<>infoprod^{1}', @UssdCode + ',' + @TarfCode)  AS '@data',
	                   @index AS '@order',
	                   N'🔔 اطلاع رسانی تخفیفات' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      ELSE
	      BEGIN
	         -- Next Step #. اعلان و اطلاع رسانی شگفت انگیز
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};amzgnoti-{1}$del#<>infoprod^{1}', @UssdCode + ',' + @TarfCode)  AS '@data',
	                   @index AS '@order',
	                   N'🔕 عدم اطلاع رسانی تخفیفات' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      -- اگر کالا ناموجود باشد
	      IF EXISTS (SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @TarfCode AND rp.CRNT_NUMB_DNRM = 0)
	      BEGIN
	         -- آیا اطلاع رسانی جهت افزایش موجودی ثبت شده یا خیر
	         IF NOT EXISTS (SELECT * FROM dbo.Service_Robot_Product_Signal WHERE SRBT_ROBO_RBID = @Rbid AND CHAT_ID = @Chatid AND TARF_CODE_DNRM = @TarfCode AND SEND_STAT IN ('002', '005'))
	         BEGIN 
	            -- Next Step #. موجود شدن کالا رو اطلاع رسانی کند
	            -- Dynamic
	            SET @X = (
	               SELECT dbo.STR_FRMT_U('./{0};sgnlnoti-{1}$del#<>infoprod^{1}', @UssdCode + ',' + @TarfCode)  AS '@data',
	                      @index AS '@order',
	                      N'✅ موجود شد به من اطلاع بده' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	            SET @index += 1;
	         END 
	         ELSE
	         BEGIN
	            -- Next Step #. غیرفعال کردن اطلاع رسانی از موجود کالا
	            -- Dynamic
	            SET @X = (
	               SELECT dbo.STR_FRMT_U('./{0};sgnlnoti-{1}$del#<>infoprod^{1}', @UssdCode + ',' + @TarfCode)  AS '@data',
	                      @index AS '@order',
	                      N'⛔ نیازی به اطلاع رسانی موجودی نیست' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	            SET @index += 1;
	         END 
	      END 
	      
	      -- اگر کالا قیمت های پله کانی داشته باشد
	      IF EXISTS (SELECT * FROM dbo.Robot_Product_StepPrice rps WHERE rps.TARF_CODE_DNRM = @TarfCode AND rps.STAT = '002')
	      BEGIN
	         -- Next Step #. موجود شدن کالا رو اطلاع رسانی کند
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};steppric-{1}$del#infoprod^{1}', @UssdCode + ',' + @TarfCode)  AS '@data',
                      @index AS '@order',
                      N'✨ قیمت فروش عمده' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- وقتی میخواهیم منوهای بیشتری را مشاهده کنیم
	      IF @CmndText = 'moreinfoprod' 
	      BEGIN
	         -- Next Step #. فروشنده این کالا
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};selrtarf-{1}$#', @UssdCode + ',' + @TarfCode) AS '@data',
	                   @index AS '@order',
	                   N'🗣 فروشنده کالا' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
   	      
	         -- Next Step #. فروشنده های مشابه این کالا
	         -- Dynamic
	         IF EXISTS(
	            SELECT *
	              FROM dbo.Service_Robot_Seller_Product srsp, dbo.Service_Robot_Seller_Competitor srsc
	             WHERE srsp.CODE = srsc.SRSP_CODE
	               AND srsc.SLER_TARF_CODE_ = @TarfCode
	         )
	         BEGIN	      
	            SET @X = (
	               SELECT dbo.STR_FRMT_U('./{0};selrcomptarf-{1}$#', @UssdCode + ',' + @TarfCode) AS '@data',
	                      @index AS '@order',
	                      N'👥 فروشنده کالا' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');   	      
	            SET @index += 1;
	         END;
   	      
	         -- Next Step #. بازخورد درباره کالا
	         -- Static
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};feedbackprod-{1}$del#', @UssdCode + ',' + @TarfCode)  AS '@data',
                      @index AS '@order',
                      N'🙏 بازخورد در باره کالا' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            -- Static
			SET @X = (
				SELECT dbo.STR_FRMT_U('./{0};feedback:product:rating-{1}$del,lessfdbkprod#' , @UssdCode + ',' + @TarfCode) AS '@data',
				  	   @index AS '@order',
					   N'⭐ امتیازی که به کالا میدین چیه؟' AS "text()"
				   FOR XML PATH('InlineKeyboardButton')
			);
			SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
			SET @index += 1;
   	      
	         -- Next Step #. قیمت مناسبتری سراغ دارید
	         -- Static
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};findbestprictarf-{1}$#', @UssdCode + ',' + @TarfCode) AS '@data',
                      @index AS '@order',
                      N'💸 قیمت مناسب تری سراغ دارید' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            -- Next Step #. بقیه عکس محصول
            -- Dynamic
            IF(SELECT COUNT(p.CODE)
                 FROM dbo.Robot_Product p, dbo.Robot_Product_Preview spp
                WHERE p.ROBO_RBID = @Rbid
                  AND p.CODE = spp.RBPR_CODE
                  AND p.TARF_CODE = @TarfCode ) > 1
            BEGIN
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./{0};showimagprod-{1}$#', @UssdCode + ',' + @TarfCode) AS '@data',
                         @index AS '@order',
                         N'🎠 پیش نمایش محصول' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
            END;
            
            -- Next Step #. اگر محصول اشانطیون داشته باشد
            -- Dynamic
            IF EXISTS(
               SELECT *
                 FROM dbo.Service_Robot_Seller_Product_Gift pg, dbo.Service_Robot_Seller_Product sp, dbo.Robot_Product rp
                WHERE pg.TARF_CODE_DNRM = @TarfCode 
                  AND pg.STAT = '002'
                  AND pg.SSPG_CODE = sp.CODE
                  AND sp.CRNT_NUMB_DNRM > 0
                  AND sp.TARF_CODE = rp.TARF_CODE
                  AND rp.ROBO_RBID = @Rbid
                  AND rp.STAT = '002'
            )
            BEGIN
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./{0};showgiftslerprod-{1}$#', @UssdCode + ',' + @TarfCode) AS '@data',
                         @index AS '@order',
                         N'👓 هدیه های محصول' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
            END 
            
            -- Next Step #. بقیه محصولات این فروشنده
            -- Dynamic
            IF(SELECT COUNT(srsp.CODE)
                 FROM dbo.Service_Robot_Seller srs, dbo.Service_Robot_Seller_Product srsp
                WHERE srs.CODE = srsp.SRBS_CODE
                  AND srsp.TARF_CODE = @TarfCode ) > 1
            BEGIN
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./{0};showothrslertarf-{1}$#', @UssdCode + ',' + @TarfCode) AS '@data',
                         @index AS '@order',
                         N'👓 بقیه محصولات این فروشنده' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
            END;
            
            -- Next Step #. بقیه محصولات این برند
            -- Dynamic
            --IF(SELECT COUNT(srsp.CODE)
            --     FROM dbo.Robot_Product rp, dbo.Robot_Product rpo, dbo.Service_Robot_Seller srs, 
            --          dbo.Service_Robot_Seller_Product srsp, 
            --          dbo.Service_Robot_Seller_Product srso
            --    WHERE srs.CODE = srsp.SRBS_CODE -- کالایی که از قفس فروشنده انتخاب شده 
            --      AND srs.CODE = srso.SRBS_CODE -- بقیه کالاهای همین برند انتخاب شده از قفسه فروشنده
                  
            --      AND rp.ROBO_RBID = @Rbid -- کالاهای مربوط به همین ربات
            --      AND rpo.ROBO_RBID = @Rbid -- کالاهای مربوط به همین ربات
                  
            --      AND srsp.TARF_CODE = rp.TARF_CODE -- کالای انتخاب شده این فروشنده که درون ربات شناخته شده
                  
            --      AND srsp.TARF_CODE = @TarfCode -- انتخاب کالای مورد نظر انتخاب از قفسه فروشنده
                  
            --      AND srsp.TARF_CODE != srso.TARF_CODE -- حالا برای دنبال کردن بقیه کالا های فروشنده
                  
            --      AND srso.TARF_CODE = rpo.TARF_CODE -- بقیه کالاهایی که درون محصولات ربات قرار گرفته اند
                  
            --      AND rp.BRND_CODE_DNRM = rpo.BRND_CODE_DNRM -- پیدا کردن بقیه برندهای این کالا در قفسه فروشنده
            --  ) > 0
            --BEGIN
            --   SET @X = (
            --      SELECT dbo.STR_FRMT_U('./{0};showothrslerbrndprod-{1}$#', @UssdCode + ',' + @TarfCode) AS '@data',
            --             @index AS '@order',
            --             N'✨ بقیه محصولات همین برند' AS "text()"
            --         FOR XML PATH('InlineKeyboardButton')
            --   );
            --   SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            --   SET @index += 1;
            --END;
            
            -- اضافه کردن کالا های مرتبط
            IF EXISTS (
                  SELECT * 
                    FROM dbo.Robot_Product rp
                   WHERE rp.ROBO_RBID = @Rbid
                     AND rp.TARF_CODE != @TarfCode
                     AND (
                            EXISTS ( -- کالاهایی که در یک گروه یا برند یا سوپر گروه باشند
                              SELECT *
                                FROM dbo.Robot_Product rpgbs
                               WHERE rp.ROBO_RBID = rpgbs.ROBO_RBID
                                 and rp.TARF_CODE = @TarfCode
                                 AND (
                                       rp.GROP_CODE_DNRM = rpgbs.GROP_CODE_DNRM OR
                                       rp.BRND_CODE_DNRM = rpgbs.BRND_CODE_DNRM OR
                                       rp.GROP_JOIN_DNRM = rpgbs.GROP_JOIN_DNRM                                                                     
                                     )
                            ) OR 
                           EXISTS ( -- آیا کالا محصول جایگزین دارد یا خیر                           
                              SELECT *
                                FROM dbo.Robot_Product_Alternative rpa
                               WHERE rp.CODE = rpa.RBPR_CODE
                                 AND rpa.TARF_CODE_DNRM = @TarfCode                               
                                 AND rpa.STAT = '002'
                           )
                         )
               )
            BEGIN
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./{0};showothrlinkprod-{1}$#', @UssdCode + ',' + @TarfCode) AS '@data',
                         @index AS '@order',
                         N'✨ محصولات مرتبط' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
            END 
            
            -- Next Step #. محصولات مرتبط و جایگزین
            -- Dynamic
            
            -- Next Step #. Less Menu
            -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$del,lessinfoprod#', @UssdCode + ',' + @TarfCode) AS '@data',
                      @index AS '@order',
                      N'⬆️ بازگشت' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
         ELSE IF @CmndText = 'lessinfoprod'
         BEGIN
            -- Next Step #. More Menu
            -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$del,moreinfoprod#', @UssdCode + ',' + @TarfCode) AS '@data',
                      @index AS '@order',
                      N'🔵 بیشتر' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         
         -- Next Step #. More Menu
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⛔ بستن' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END; -- IF @CmndText IN ( 'moreinfoprod', 'lessinfoprod' )
	   ELSE IF @CmndText IN ( 'moreinfoinvc', 'lessinfoinvc' )
	   BEGIN
	      IF @CmndText IN ( 'lessinfoinvc' ) 
	      BEGIN
	         -- Next Step #. Payment Operation
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lessshipcart#' , '*0*5#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'🚚 نحوه ارسال' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;

            -- مشتری تا زمانی که آدرس ارسال بسته خود را مشخص نکند اجازه پرداخت را ندارد   	      
   	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND o.HOW_SHIP != '000')
   	      BEGIN
	            -- اگر مشتری مشخص کرده باشد که با پیک یا باربری سفارش ارسال شود
	            IF NOT EXISTS(SELECT * FROM dbo.[Order] o, dbo.Robot R WHERE R.RBID = O.SRBT_ROBO_RBID AND o.CODE = @OrdrCode AND ( ( o.HOW_SHIP = ( '002' ) AND O.DEBT_DNRM >= R.FREE_SHIP_INCT_AMNT ) OR ( o.HOW_SHIP = ( '003' ) AND O.DEBT_DNRM >= R.FREE_SHIP_OTCT_AMNT ) ) )
	            BEGIN
	               -- Next Step #. Payment Operation
	               -- Static
	               SET @X = (
	                  SELECT dbo.STR_FRMT_U('./{0};costshipcart-{1}$del,lessckotcart#' , '*0*9*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                         @index AS '@order',
	                         N'💸 هزینه ارسال' AS "text()"
	                     FOR XML PATH('InlineKeyboardButton')
	               );
	               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	               SET @index += 1;
	            END 	            
	            
	            -- Next Step #. Payment Operation
	            -- Static
	            SET @X = (
	               SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessckotcart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                      @index AS '@order',
	                      N'💳 نحوه پرداخت' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	            SET @index += 1;
	         END 
	      END
	      
	      IF @CmndText = 'moreinfoinvc'
	      BEGIN
	         -- Next Step #. Edit Invoice
	         -- Static
	         SET @X = (
	            SELECT CASE 
	                        WHEN od.ELMN_TYPE IN ('001') THEN 	                        
	                            dbo.STR_FRMT_U('./{0};infoprod-{1}$lessinfoprod#', @UssdCode + ',' + od.TARF_CODE) 
	                        WHEN od.ELMN_TYPE IN ('002', '003') THEN 
	                           dbo.STR_FRMT_U('./{0};infoprod-{1},{2}$lessinfogfto#', @UssdCode + ',' + CAST(od.ORDR_CODE AS VARCHAR(30)) + ',' + CAST(od.RWNO AS VARCHAR(30))) 
	                   END AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY od.TARF_CODE ) AS '@order',
                      N'📦 ' + SUBSTRING(od.ORDR_DESC, 1, 30) + REPLACE(N' ••• 👈 {0}', N'{0}', od.NUMB) AS "text()"	                        
	              FROM dbo.Order_Detail od
	             WHERE od.ORDR_CODE = @OrdrCode
	             ORDER BY od.TARF_CODE
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	         
	         -- برای تنظیم ردیف منوها
	         SELECT @index += COUNT(od.RWNO) + 1
              FROM dbo.Order_Detail od
             WHERE od.ORDR_CODE = @OrdrCode;
             
	         -- اضافه کردن منوهایی مانند اضافه کردن محصولات جدید
	         -- Next Step #. Add New Product So Show Products *0#, *0*0#
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};showcart-{1}$del,lessinfoinvc#' , @UssdCode + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
	                   @index AS '@order',
	                   N'💾 ثبت تغییرات' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END
	      ELSE IF @CmndText = 'lessinfoinvc'
	      BEGIN
	         -- Next Step #. Edit Invoice
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};scdlptntcart-{1}$del,lessinfoinvc#' , '*0*9*1#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'📅 نوبت دهی' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;	         
	         
	         -- Next Step #. Edit Invoice
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};trancart2othr-{1}$del,lessinfoinvc#' , '*0*9*2#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'📤 انتقال فاکتور به مشتری دیگر' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;	         
	         
	         -- Next Step #. Edit Invoice
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};showcart-{1}$del,moreinfoinvc#' , @UssdCode + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'📝 ویرایش فاکتور' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;	         
	         
	         -- Next Step #. Remove Cart
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};remvcart-{1}$del,addnewprod#' , @UssdCode + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
	                   @index AS '@order',
	                   N'❌ انصراف از خرید' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END	      
	      -- اضافه کردن منوهایی مانند اضافه کردن محصولات جدید
         -- Next Step #. Add New Product So Show Products *0#, *0*0#
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};showprods-$del#' , @UssdCode) AS '@data',
                   @index AS '@order',
                   N'📝 افزودن کالای جدید' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Next Step #. More Menu
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⛔ بستن' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END -- IF @CmndText = 'cretfrstmenucart'
	   ELSE IF @CmndText IN ( 'numbprodcart' )
	   BEGIN
		  -- اضافه شدن رنج کلیو برای محصولاتی که قابلیت فروش گرمی هم دارن
		  IF EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @TarfCode AND rp.NUMB_TYPE = '002')
		  BEGIN
			  -- Next Step #. تعداد کالا را 5 واحد اضافه میکنیم
			  -- Static
			  SET @X = (
				 SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
						dbo.STR_FRMT_U('./{0};addcart-{1}*+=0.25$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
						@index AS '@order',
						N'➕ 250 گرم' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
			  );
			  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
			  SET @index += 1;
			  
			  -- Next Step #. تعداد کالا را 5 واحد اضافه میکنیم
			  -- Static
			  SET @X = (
				 SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
						dbo.STR_FRMT_U('./{0};addcart-{1}*+=0.5$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
						@index AS '@order',
						N'➕ 500 گرم' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
			  );
			  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
			  SET @index += 1;			  
		  END 
		  
	      -- Next Step #. تعداد کالا را یک واحد اضافه میکنیم
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'➕ 1' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. تعداد کالا را 5 واحد اضافه میکنیم
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};addcart-{1}*+=5$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'➕ 5' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. تعداد کالا را ده واحد اضافه میکنیم
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};addcart-{1}*+=10$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'➕ 10' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. نمایش سبد خرید
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};showcart-{1}$del,lessinfoinvc#' , @UssdCode + ',' + CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
	                @index AS '@order',
	                N'📑 نمایش سبد خرید' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- کاهش دادن رنج کلیو برای محصولاتی که قابلیت فروش گرمی هم دارن
		  IF EXISTS(SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @Rbid AND rp.TARF_CODE = @TarfCode AND rp.NUMB_TYPE = '002')
		  BEGIN
			  -- Next Step #. تعداد کالا را 5 واحد اضافه میکنیم
			  -- Static
			  SET @X = (
				 SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
						dbo.STR_FRMT_U('./{0};addcart-{1}*-=0.25$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
						@index AS '@order',
						N'➖ 250 گرم' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
			  );
			  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
			  SET @index += 1;
			  
			  -- Next Step #. تعداد کالا را 5 واحد اضافه میکنیم
			  -- Static
			  SET @X = (
				 SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
						dbo.STR_FRMT_U('./{0};addcart-{1}*-=0.5$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
						@index AS '@order',
						N'➖ 500 گرم' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
			  );
			  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
			  SET @index += 1;			  
		  END 
		  
	      -- Next Step #. تعداد کالا را یک واحد کم میکنیم
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};addcart-{1}*--$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'➖ 1' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. تعداد کالا را 5 واحد کم میکنیم
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};addcart-{1}*-=5$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'➖ 5' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. تعداد کالا را ده واحد کم میکنیم
	      -- Static
	      SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};addcart-{1}*-=10$del#<>numbprodcart^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'➖ 10' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. Less Menu
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$del,lessinfoprod#', '*0#' + ',' + @TarfCode) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Next Step #. More Menu
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⛔ بستن' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'sortprod' )
	   BEGIN
	      SET @ParamsText = (
	         SELECT CASE WHEN id = 1 THEN Item + N',' -- Filter Text
	                     WHEN id = 2 THEN Item + N',' -- Sort
	                END 
	           FROM dbo.SplitString(@ParamsText, ',')
	          WHERE id IN (1, 2)
	            FOR XML PATH('')
	      );
	      
	      -- Next Step #. پربازدید ترین
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};findprod-{1},{2},1$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
	                @index AS '@order',
	                N'👀 پربازدید ترین' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. پرفروش ترین
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};findprod-{1},{2},2$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
	                @index AS '@order',
	                N'💰 پرفروش ترین' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. محبوب ترین
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};findprod-{1},{2},3$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
	                @index AS '@order',
	                N'❤️ محبوب ترین' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. جدید ترین
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};findprod-{1},{2},4$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
	                @index AS '@order',
	                N'⭐️ جدید ترین' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. ارزان ترین
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};findprod-{1},{2},5$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
	                @index AS '@order',
	                N'🤑 ارزان ترین' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. گران ترین
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};findprod-{1},{2},6$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
	                @index AS '@order',
	                N'💎 گران ترین' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. سریع ترین ارسال
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};findprod-{1},{2},7$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
	                @index AS '@order',
	                N'💫 سریع ترین ارسال' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. کالاهای موجود
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};findprod-{1},{2},8$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
	                @index AS '@order',
	                N'✅ محصولات موجود' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. بازگشت
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};findprod-{1}$del#' , @UssdCode + ',' + @ParamsText) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'addnewprod' )
	   BEGIN
	      -- اضافه کردن منوهایی مانند اضافه کردن محصولات جدید
         -- Next Step #. Add New Product So Show Products *0#, *0*0#
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};showprods-$del#' , @UssdCode) AS '@data',
                   @index AS '@order',
                   N'📝 افزودن کالای جدید' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lessckotcart', 'moreckotcart' )
	   BEGIN
	      -- اضافه کردن مدت زمان ده دقیقه به درخواست برای پرداخت
	      UPDATE dbo.[Order] 	      
	         SET STRT_DATE = DATEADD(MINUTE, 10, o.STRT_DATE) 
	        FROM dbo.[Order] o, dbo.Robot r
	       WHERE r.RBID = o.SRBT_ROBO_RBID
	         AND CODE = @OrdrCode
	         AND ABS(DATEDIFF(MINUTE, DATEADD(MINUTE, r.ORDR_EXPR_TIME, STRT_DATE), GETDATE())) < 10;
	      
	      IF EXISTS(SELECT * FROM dbo.[Order] WHERE CODE = @OrdrCode AND DEBT_DNRM > 0)
	      BEGIN
	         -- Next Step #. Payment
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};-{1}$pay#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'💳 کارت به کارت' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         SET @X = (
	            SELECT '' AS '@data',
	                   dbo.STR_FRMT_U(N'https://idpay.ir/{0}?amount={1}&name={2}&phone={3}&desc={4}', b.IDPY_ADRS_DNRM + N',' + CAST(CASE o.AMNT_TYPE WHEN '001' THEN o.DEBT_DNRM WHEN '002' THEN o.DEBT_DNRM * 10 END  AS NVARCHAR(50)) + N',' + o.OWNR_NAME + N',' + o.CELL_PHON + N',' + CAST(o.CODE AS NVARCHAR(50)))  AS '@url',
	                   @index AS '@order',
	                   N'🦋 پرداخت' AS "text()"
	              FROM dbo.[Order] o, dbo.Service_Robot_Card_Bank b
	             WHERE o.CODE = @OrdrCode
	               AND o.DEST_CARD_NUMB_DNRM = b.CARD_NUMB_DNRM
	               AND o.ORDR_TYPE = b.ORDR_TYPE_DNRM
	               AND b.ACNT_STAT_DNRM = '002'
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('@/FRST_PAGE_F;chkotrcpt-{0}$#', @OrdrCode) AS '@data',	                   
	                   @index AS '@order',
	                   N'❗ استعلام وضعیت پرداخت' AS "text()"
	              FROM dbo.[Order] o, dbo.Service_Robot_Card_Bank b
	             WHERE o.CODE = @OrdrCode
	               AND o.DEST_CARD_NUMB_DNRM = b.CARD_NUMB_DNRM
	               AND o.ORDR_TYPE = b.ORDR_TYPE_DNRM
	               AND b.ACNT_STAT_DNRM = '002'
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      IF EXISTS(SELECT * FROM dbo.Service_Robot_Discount_Card WHERE SRBT_ROBO_RBID = @Rbid AND CHAT_ID = @Chatid AND VALD_TYPE = '002')
	      BEGIN
	         -- Next Step #. Discount Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessdsctcart#' , '*0*3*1#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'💸 کارت تخفیف' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      IF EXISTS(SELECT * FROM dbo.Service_Robot_Gift_Card WHERE SRBT_ROBO_RBID = @Rbid AND CHAT_ID = @Chatid AND VALD_TYPE = '002')
	      BEGIN 
	         -- Next Step #. Gift Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessgiftcart#' , '*0*3*2#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'💳 کارت هدیه' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      -- Next Step #. Wallet Card
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lesswletcart#' , '*0*3*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'💎 کیف پول' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. Recipt Pay Card
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessrcptcart#' , '*0*3*4#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'📃 ارسال تصویر رسید پرداخت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001', '002', '005'))
	      BEGIN 
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lessinfocart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)))  AS '@data',
                      @index AS '@order',
                      N'👓 مشاهده اطلاعات فاکتور' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND ISNULL(o.DEBT_DNRM, 0) = 0)
	      BEGIN
	         -- Next Step #. Recipt Pay Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};finalcart-{1}$del,lessfinlcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⚡️ پایان سفارش' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessinfoinvc#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessinfocart' )
	   BEGIN
         -- رکورد های مربوط به تخفیفات
         SET @X = (
             SELECT dbo.STR_FRMT_U('./{0};deldsctcart-{1}$del,lessinfocart#', @UssdCode + ',' + CAST(d.DCID AS VARCHAR(30))) AS '@data',
                    ROW_NUMBER() OVER ( ORDER BY os.code ) AS '@order',
                    N'❌ کارت تخفیف ' + 
                    CASE d.OFF_KIND
                         WHEN '001' /* تخفیف عادی */ THEN CAST(d.OFF_PRCT AS VARCHAR(3)) + N'%'
                         WHEN '002' /* تخفیف شانس گردونه */ THEN 
                               CASE 
                                    WHEN ISNULL(d.OFF_PRCT, 0) != 0 THEN CAST(d.OFF_PRCT AS VARCHAR(3)) + N'%'
                                    ELSE REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, d.MAX_AMNT_OFF), 1), '.00', '') + N''
                               END 
                         WHEN '004' /* تخفیف فروش همکار */ THEN CAST(d.OFF_PRCT AS VARCHAR(3)) + N'%'
                    END AS "text()"
               FROM dbo.Order_State os, dbo.Service_Robot_Discount_Card d
              WHERE os.ORDR_CODE = @OrdrCode
                AND os.DISC_DCID = d.DCID
                AND os.AMNT_TYPE = '002'
                FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
         -- رکورد های مربوط به واریزی های کارت اعتباری
         SET @X = (
             SELECT dbo.STR_FRMT_U('./{0};delgiftcart-{1}$del,lessinfocart#', @UssdCode + ',' + CAST(g.GCID AS VARCHAR(30))) AS '@data',
                    ROW_NUMBER() OVER ( ORDER BY os.code ) AS '@order',
                    N'❌ کارت اعتباری ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, g.TEMP_AMNT_USE), 1), '.00', '')
                     AS "text()"
               FROM dbo.Order_State os, dbo.Service_Robot_Gift_Card g
              WHERE os.ORDR_CODE = @OrdrCode
                AND os.GIFC_GCID = g.GCID
                AND os.AMNT_TYPE = '001'
                FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
         -- کیف پول
         SET @X = (
             SELECT dbo.STR_FRMT_U('./{0};del' + CASE w.WLET_TYPE WHEN '001' THEN 'credit' WHEN '002' THEN 'cash' END  + 'wletcart-{1}$del,lessinfocart#', @UssdCode + ',' + CAST(wd.CODE AS VARCHAR(30))) AS '@data',
                    ROW_NUMBER() OVER ( ORDER BY os.code ) AS '@order',
                    N'❌ کیف پول ' + wt.DOMN_DESC + N' ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, wd.AMNT), 1), '.00', '')
                     AS "text()"
               FROM dbo.Order_State os, dbo.Wallet_Detail wd, dbo.Wallet w, dbo.[D$WLTP] wt
              WHERE os.ORDR_CODE = @OrdrCode
                AND os.WLDT_CODE = wd.CODE
                AND wd.WLET_CODE = w.CODE
                AND w.WLET_TYPE = wt.VALU
                FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
         -- رسید های پرداخت
         -- تایید نشده
         SET @X = (
             SELECT dbo.STR_FRMT_U('./{0};rcptcart-{1}$del,lessinfocart#', @UssdCode + ',' + CAST(os.CODE AS VARCHAR(30))) AS '@data',
                    ROW_NUMBER() OVER ( ORDER BY os.code ) AS '@order',
                    N'❌ رسید تایید نشده ' + 
                    CASE ISNULL(os.AMNT, 0) 
                         WHEN 0 THEN ' '
                         ELSE REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '')
                    END AS "text()"
               FROM dbo.Order_State os
              WHERE os.ORDR_CODE = @OrdrCode
                AND os.AMNT_TYPE = '005'
                AND os.CONF_STAT = '003'
                FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
         
         -- تایید شده
         SET @X = (
             SELECT dbo.STR_FRMT_U('./{0};delrcptcart-{1}$del,lessinfocart#', @UssdCode + ',' + CAST(os.CODE AS VARCHAR(30))) AS '@data',
                    ROW_NUMBER() OVER ( ORDER BY os.code ) AS '@order',
                    N'❌ رسید تایید شده ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '')
                     AS "text()"
               FROM dbo.Order_State os
              WHERE os.ORDR_CODE = @OrdrCode
                AND os.AMNT_TYPE = '005'
                AND os.CONF_STAT = '002'
                FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
         
         -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessckotcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessfinlcart', 'lesshistcart' )
	   BEGIN
 	      -- Next Step #. How Shipping
	      -- Static
	      --SET @X = (
	      --   SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lessshipcart#' , '*0*5#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	      --          @index AS '@order',
	      --          N'🚚 نحوه ارسال' AS "text()"
	      --      FOR XML PATH('InlineKeyboardButton')
	      --);
	      --SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      --SET @index += 1;
	      
	      -- Next Step #. Your Order
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lesstarfcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'🛍 سفارش شما' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. Order Status
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};ordrstat-{1}$del,lesstarfcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'🔦 وضعیت سفارش' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- اگر مشتری سفارش خود را درب فروشگاه بخواهد تحویل بگیرد
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND o.HOW_SHIP = '001' /* تحویل درب فروشگاه */)
	      BEGIN
	         IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.ORDR_CODE = @OrdrCode AND o.ORDR_TYPE = '018' /* شغل انباردار */ AND o.ORDR_STAT = '014' /* جمع آوری و بسته بندی سفارش */)
	         BEGIN
	            -- Next Step #. Order Status
	            -- Dynamic
	            SET @X = (
	               SELECT dbo.STR_FRMT_U('./*0#;custman::takeordr-{0}$#' , @OrdrCode) AS '@data',
	                      @index AS '@order',
	                      N'👈📦 درخواست سفارش' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	            SET @index += 1;
	         END 
	         ELSE IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.ORDR_CODE = @OrdrCode AND o.ORDR_TYPE = '018' /* شغل انباردار */ AND o.ORDR_STAT = '015' /* خروج و تحویل سفارش به مشتری */)
	         BEGIN
	            -- Next Step #. Order Status
	            -- Dynamic
	            SET @X = (
	               SELECT dbo.STR_FRMT_U('./*0#;custman::getordr-{0}$#' , @OrdrCode) AS '@data',
	                      @index AS '@order',
	                      N'👈📦 تحویل سفارش' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	            SET @index += 1;
	         END 
	      END 
	      
	      -- Next Step #. Order Survey
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};writerating-{1}$del,lesswrtgcart#' , '*0*5#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⭐️ نظرسنجی' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;	      
	      
	      -- Next Step #. New Order
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lessshipcart#' , '*0*5#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⚡️ سفارش جدید' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lesswrtgcart', 'morewrtgcart' )
	   BEGIN
	      IF @CmndText = 'lesswrtgcart'
	      begin
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('!./{0};writerating-{1},001$del,morewrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'📱 نرم افزار فروشگاه' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('!./{0};writerating-{1},002$del,morewrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'🎪 فروشگاه' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('!./{0};writerating-{1},003$del,morewrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'🗣 فروشنده' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('!./{0};writerating-{1},004$del,morewrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'🛍 محصولات فروشگاه' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('!./{0};writerating-{1},005$del,morewrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'📦 بسته بندی سفارشات' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('!./{0};writerating-{1},006$del,morewrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'🚚 مدت زمان تحویل سفارش' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
   	      
	         -- Next Step #. Backup to UP MENU
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lesshistcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⤴️ بازگشت' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END
	      ELSE IF @CmndText = 'morewrtgcart'
	      BEGIN
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};writerating-{1},{2},1$del,lesswrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) + ',' + CAST(@SrorCode AS VARCHAR(30))) AS '@data',
	                   @index AS '@order',
	                   N'⭐️ ' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};writerating-{1},{2},1$del,lesswrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) + ',' + CAST(@SrorCode AS VARCHAR(30))) AS '@data',
	                   @index AS '@order',
	                   N'⭐️⭐️ ' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};writerating-{1},{2},3$del,lesswrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) + ',' + CAST(@SrorCode AS VARCHAR(30))) AS '@data',
	                   @index AS '@order',
	                   N'⭐️⭐️⭐️ ' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};writerating-{1},{2},4$del,lesswrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) + ',' + CAST(@SrorCode AS VARCHAR(30))) AS '@data',
	                   @index AS '@order',
	                   N'⭐️⭐️⭐️⭐️ ' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};writerating-{1},{2},5$del,lesswrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) + ',' + CAST(@SrorCode AS VARCHAR(30))) AS '@data',
	                   @index AS '@order',
	                   N'⭐️⭐️⭐️⭐️⭐️ ' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	         
	         -- Next Step #. Backup to UP MENU
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};writerating-{1}$del,lesswrtgcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⤴️ بازگشت' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	   END 	   
	   ELSE IF @CmndText IN ('lessdsctcart')
	   BEGIN
         -- آیا تخفیفی وجود دارد که بخواهیم برای آن بررسی انجام دهیم
         IF EXISTS(
            SELECT *
              FROM dbo.Service_Robot_Discount_Card a
             WHERE a.CHAT_ID = @Chatid
               AND a.SRBT_ROBO_RBID = @Rbid
               AND ISNULL(a.EXPR_DATE, GETDATE()) >= GETDATE()
               AND a.VALD_TYPE = '002' -- معتبر باشد	      
         )
         BEGIN
            -- بررسی اینکه ایا در این سفارش کد تخفیف وارد کرده یا خیر
            -- اگر کد تخفیفی وارد نشده باشد از عبارت adddsctcart
            -- و اگر وارد شده باشد از گزینه replacedsctcart استفاده میکنیم
            IF NOT EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '002' AND os.CONF_STAT = '002' /* Waiting for Confirm */)
               SET @CmndText = 'adddsctcart'
            ELSE 
               SET @CmndText = 'replacedsctcart';
	         
            -- Next Step #. Show Discount Card
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};{1}-{2}$del,lessinfodsct#', '*0*3*1#' + ',' + @CmndText + ',' + CAST(od.DCID AS VARCHAR(30))) AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY od.EXPR_DATE ) AS '@order',
                      CASE od.OFF_KIND 
                           WHEN '004' THEN N'⏳ تخفیف ویژه همکار فروش ••• '  
                           ELSE REPLACE(N'⏳ {0} روز باقیمانده ••• ', N'{0}', DATEDIFF(DAY, GETDATE(), od.EXPR_DATE))
                      END +
                      ISNULL(od.DISC_CODE, N' ') + 
                      CASE WHEN od.OFF_KIND = '002' /* تخفیف گردونه */ THEN 
                                CASE WHEN (o.DEBT_DNRM) >= od.FROM_AMNT AND @CmndText = 'adddsctcart' THEN N' ✅ '
                                     WHEN @CmndText = 'replacedsctcart' THEN N' ✏️ '
                                     ELSE N' ⛔️ '
                                END + N'💫'
                           WHEN od.OFF_KIND = '001' /* تخفیف عادی */ THEN 
                                CASE WHEN EXISTS(SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND ISNULL(od.OFF_PRCT, 0) = 0) AND @CmndText = 'adddsctcart' THEN N' ✅ ' -- N' ✅ 🔥 ' 
                                     WHEN @CmndText = 'replacedsctcart' THEN N' ✏️ '
                                     ELSE N' ⛔️ ' 
                                END + N' 🔥 ' 
                           WHEN od.OFF_KIND = '004' THEN 
                                CASE WHEN EXISTS(SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = @OrdrCode AND ISNULL(od.OFF_PRCT, 0) = 0) AND @CmndText = 'adddsctcart' THEN N' ✅ ' -- N' ✅ 🔥 ' 
                                     WHEN @CmndText = 'replacedsctcart' THEN N' ✏️ '
                                     ELSE N' ⛔️ ' 
                                END + N' 🤝 ' 
                      END AS "text()"
                 FROM dbo.Service_Robot_Discount_Card od, dbo.[Order] o
                WHERE od.CHAT_ID = @Chatid
                  AND od.SRBT_ROBO_RBID = @Rbid
                  AND o.SRBT_ROBO_RBID = @Rbid
                  AND o.CHAT_ID = @Chatid
                  AND o.CODE = @OrdrCode
                  AND ISNULL(od.EXPR_DATE, GETDATE()) >= GETDATE() -- تاریخ همچنان باقی داشته باشد
                  AND od.VALD_TYPE = '002' -- معتبر باشد                  
                ORDER BY od.EXPR_DATE 
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	         
         END 
         
         IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001', '002', '005'))
	      BEGIN 
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lessinfocart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)))  AS '@data',
                      @index AS '@order',
                      N'👓 مشاهده اطلاعات فاکتور' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND ISNULL(o.DEBT_DNRM, 0) = 0)
	      BEGIN
	         -- Next Step #. Recipt Pay Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};finalcart-{1}$del,lessfinlcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⚡️ پایان سفارش' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
         
         -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessckotcart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END
	   ELSE IF @CmndText IN ('lessinfodsct', 'lesseditdsct')
	   BEGIN
	      IF @CmndText = 'lesseditdsct'
	      BEGIN
	         -- Next Step #. 
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};deldsctcart-{1}$del,lessdsctcart#' , '*0*3*1#' + ',' + CAST(@discdcid AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'❌ حذف کد تخفیف' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessdsctcart#' , '*0*3*1#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessgiftcart' ) 
	   BEGIN
	      -- بررسی اینکه آیا ما رکوردی برای کارت هدیه مشتری داریم یا خیر
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Service_Robot_Gift_Card a
	          WHERE a.SRBT_ROBO_RBID = @Rbid
	            AND a.CHAT_ID = @Chatid
	            AND a.VALD_TYPE = '002'
	            AND a.BLNC_AMNT_DNRM >= 0
	      )
	      BEGIN
	         -- Next Step #. Show Discount Card
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};addgiftcart-{1}$lessinfogift#', '*0*3*2#' + ',' + CAST(g.GCID AS VARCHAR(30))) AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY g.AMNT DESC ) AS '@order',
                      REPLACE(N'💰 {0} مبلغ اعتبار ••• ', N'{0}', REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, g.BLNC_AMNT_DNRM - ISNULL(g.TEMP_AMNT_USE, 0)), 1), '.00', '')) +
                      g.CARD_NUMB AS "text()"
                 FROM dbo.Service_Robot_Gift_Card g, dbo.[Order] o
                WHERE g.CHAT_ID = @Chatid
                  AND g.SRBT_ROBO_RBID = @Rbid
                  AND o.SRBT_ROBO_RBID = @Rbid
                  AND o.CHAT_ID = @Chatid
                  AND o.CODE = @OrdrCode
                  AND (g.BLNC_AMNT_DNRM - ISNULL(g.TEMP_AMNT_USE, 0)) > 0 -- باقیمانده مبلغ اعتبار
                  AND g.VALD_TYPE = '002' -- معتبر باشد                  
                ORDER BY g.AMNT DESC 
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	      END 

         -- اگر برای سفارش ردیف پرداختی / تخفیف / رسید پرداخت زده شده باشد
	      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001', '002', '005'))
	      BEGIN 
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lessinfocart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)))  AS '@data',
                      @index AS '@order',
                      N'👓 مشاهده اطلاعات فاکتور' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- اگر سفارش در حالت تسویه حساب یاشد
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND ISNULL(o.DEBT_DNRM, 0) = 0)
	      BEGIN
	         -- Next Step #. Recipt Pay Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};finalcart-{1}$del,lessfinlcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⚡️ پایان سفارش' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessckotcart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessinfogfto', 'lessinfogftp' )
	   BEGIN
	      SELECT @Numb = od.NUMB , @OrdrCode = od.ORDR_CODE, @OrdrRwno = od.RWNO
           FROM dbo.[Order] o, dbo.Order_Detail od
          WHERE o.CODE = od.ORDR_CODE
            AND o.CHAT_ID = @Chatid
            AND o.SRBT_ROBO_RBID = @Rbid
            AND o.ORDR_TYPE = '004'
            AND o.ORDR_STAT = '001'
            AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE)
            AND od.TARF_CODE = @TarfCode;
         
         IF @Numb IS NOT NULL
         BEGIN 
	         -- Next Step #. ویرایش متن کارت اعتباری
	         -- Dynamic
	         SET @X = (
	            SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                   dbo.STR_FRMT_U('./{0};editgfto-{1},{2}$del#' , '*0*6*5*3#' + ',' + CAST(@OrdrCode AS VARCHAR(30)) + ',' + CAST(@OrdrRwno AS VARCHAR(30))) AS '@data',
	                   @index AS '@order',
	                   N'✏️ ویرایش پیام و مبلغ کارت اعتباری' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      end 
	      ELSE
	      BEGIN
	         -- Next Step #. افزودن کارت اعتباری به سبد خرید
	         -- Dynamic
	         SET @X = (
	         SELECT --dbo.STR_FRMT_U('./{0};addcart-{1}*++$del#>>infoprod^{1}' , @UssdCode + ',' + @TarfCode) AS '@data',
	                dbo.STR_FRMT_U('./{0};addcart-{1},{2}$del#' , '*0*6*5*3#' + ',' + @TarfCode + ',' + CAST(@RbppCode AS VARCHAR(30))) AS '@data',
	                @index AS '@order',
	                N'➕ افزودن به سبد خرید' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      END 
	      -- Next Step #. حذف کردن از سبد خرید
	      -- Dynamic	      
	      -- اگر کالا درون سبد خرید مشتری برای امروز قرار گرفته باشد
	      IF @Numb IS NOT NULL
	      BEGIN
	         IF @Numb = 1
	            SET @X = (
	               SELECT --dbo.STR_FRMT_U('./{0};delcart-{1}*del$del#>>infoprod^{1}', @UssdCode + ',' + @TarfCode) AS '@data',
	                      dbo.STR_FRMT_U('./{0};delcart-{1}*del$del#', @UssdCode + ',' + @TarfCode) AS '@data',
	                      @index AS '@order',
	                      N'❌ حذف کردن از سبد خرید' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	         ELSE
	            SET @X = (
	               SELECT --dbo.STR_FRMT_U('./{0};deccart-{1}*--$del#>>infoprod^{1}', @UssdCode + ',' + @TarfCode) AS '@data',
	                      dbo.STR_FRMT_U('./{0};deccart-{1}*--$del#', @UssdCode + ',' + @TarfCode) AS '@data',
	                      @index AS '@order',
	                      N'❌ کاهش تعداد محصول از سبد خرید' AS "text()"
	                  FOR XML PATH('InlineKeyboardButton')
	            );
	         
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;   
	      END;
	      
	      --- Next Step #. افزودن به لیست علاقه مندی ها
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};likeprod-{1}$del#>>infoprod^{1}', @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'❤️ افزودن به لیست علاقه مندی ها' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessinfogift' )
	   BEGIN
         -- اگر برای سفارش ردیف پرداختی / تخفیف / رسید پرداخت زده شده باشد
	      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001', '002', '005'))
	      BEGIN 
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lessinfocart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)))  AS '@data',
                      @index AS '@order',
                      N'👓 مشاهده اطلاعات فاکتور' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- اگر سفارش در حالت تسویه حساب یاشد
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND ISNULL(o.DEBT_DNRM, 0) = 0)
	      BEGIN
	         -- Next Step #. Recipt Pay Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};finalcart-{1}$del,lessfinlcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⚡️ پایان سفارش' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,{2}#' , '*0*3*2#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) + ',' + 'lessgiftcart')  AS '@data',
                   @index AS '@order',
                   N'⤴️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lesswletcart' ) 
	   BEGIN
	      -- ایا کیف پول نقدینگی موجودی دارد
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Wallet w
	          WHERE w.SRBT_ROBO_RBID = @Rbid
	            AND w.CHAT_ID = @Chatid
	            AND w.WLET_TYPE = '002' -- Cash Wallet
	            AND (w.AMNT_DNRM - ISNULL(w.TEMP_AMNT_USE, 0)) > 0
	      )
	      BEGIN
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};addcashwletcart-{1}$del,lessinfowlet#' , '*0*3*2#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) )  AS '@data',
                      @index AS '@order',
                      N'💰 مبلغ کیف پول نقدینگی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, w.AMNT_DNRM - ISNULL(w.TEMP_AMNT_USE, 0)), 1), '.00', '') + N' ' + a.DOMN_DESC  AS "text()"
                 FROM dbo.Wallet w, dbo.Robot r, dbo.[D$AMUT] a
                WHERE w.SRBT_ROBO_RBID = @Rbid
                  AND r.RBID = w.SRBT_ROBO_RBID
                  AND w.WLET_TYPE = '002' -- Cash Wallet
                  AND r.AMNT_TYPE = a.VALU
	               AND w.CHAT_ID = @Chatid
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- ایا کیف پول اعتباری موجودی دارد
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Wallet w
	          WHERE w.SRBT_ROBO_RBID = @Rbid
	            AND w.CHAT_ID = @Chatid
	            AND w.WLET_TYPE = '001' -- Credit Wallet
	            AND (w.AMNT_DNRM - ISNULL(w.TEMP_AMNT_USE, 0)) > 0
	      )
	      BEGIN
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};addcreditwletcart-{1}$del,lessinfowlet#' , '*0*3*2#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) )  AS '@data',
                      @index AS '@order',
                      N'💰 مبلغ کیف پول اعتباری ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, w.AMNT_DNRM - ISNULL(w.TEMP_AMNT_USE, 0)), 1), '.00', '') + N' ' + a.DOMN_DESC  AS "text()"
                 FROM dbo.Wallet w, dbo.Robot r, dbo.[D$AMUT] a
                WHERE w.SRBT_ROBO_RBID = @Rbid
                  AND r.RBID = w.SRBT_ROBO_RBID
                  AND w.WLET_TYPE = '001' -- Credit Wallet
                  AND r.AMNT_TYPE = a.VALU
	               AND w.CHAT_ID = @Chatid
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};addamntwlet-howinccashwlet$del,lessaddwlet#' , '*0*3*3#')  AS '@data',
                   @index AS '@order',
                   N'🔺 افزایش مبلغ کیف پول نقدینگی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         --SET @X = (
         --   SELECT dbo.STR_FRMT_U('./{0};addamntwlet-howinccreditwlet$del,lessaddwlet#' , '*0*3*3#')  AS '@data',
         --          @index AS '@order',
         --          N'🔺 افزایش مبلغ کیف پول اعتباری' AS "text()"
         --      FOR XML PATH('InlineKeyboardButton')
         --);
         --SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         --SET @index += 1;
         
         -- اگر برای سفارش ردیف پرداختی / تخفیف / رسید پرداخت زده شده باشد
	      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001', '002', '005'))
	      BEGIN 
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lessinfocart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)))  AS '@data',
                      @index AS '@order',
                      N'👓 مشاهده اطلاعات فاکتور' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- اگر سفارش در حالت تسویه حساب یاشد
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND ISNULL(o.DEBT_DNRM, 0) = 0)
	      BEGIN
	         -- Next Step #. Recipt Pay Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};finalcart-{1}$del,lessfinlcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⚡️ پایان سفارش' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessckotcart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessaddwlet' )
	   BEGIN
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND o.ORDR_TYPE = CASE @ParamsText WHEN 'howinccashwlet' THEN '015' WHEN 'howinccreditwlet' THEN '013' END AND o.DEBT_DNRM > 0)
	      BEGIN
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};-{1}$del,pay#' , /*   '*0*3*3#,' */ @UssdCode + ',' + CAST(@OrdrCode AS VARCHAR(30)) )  AS '@data',
                      @index AS '@order',
                      N'💳 پرداخت' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};emptyamntwlet-{1}$del,lessaddwlet#' , /*   '*0*3*3#,' */ @UssdCode + ',' + CAST(@OrdrCode AS VARCHAR(30)) )  AS '@data',
                      @index AS '@order',
                      N'⭕ صفر کردن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};addamntwlet-' + @ParamsText + ',200000$del,lessaddwlet#' , /*'*0*3*3#'*/ @UssdCode )  AS '@data',
                   @index AS '@order',
                   N'➕ 200,000 ریال' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};addamntwlet-' + @ParamsText + ',500000$del,lessaddwlet#' , /*'*0*3*3#'*/ @UssdCode)  AS '@data',
                   @index AS '@order',
                   N'➕ 500,000 ریال' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};addamntwlet-' + @ParamsText + ',1000000$del,lessaddwlet#' , /*'*0*3*3#'*/ @UssdCode )  AS '@data',
                   @index AS '@order',
                   N'➕ 1,000,000 ریال' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};addamntwlet-' + @ParamsText + ',5000000$del,lessaddwlet#' , /*'*0*3*3#'*/ @UssdCode )  AS '@data',
                   @index AS '@order',
                   N'➕ 5,000,000 ریال' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};addamntwlet-' + @ParamsText + ',10000000$del,lessaddwlet#' , /*'*0*3*3#'*/ @UssdCode )  AS '@data',
                   @index AS '@order',
                   N'➕ 10,000,000 ریال' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- اگر از فرم سفارش آنلاین وارد شده باشیم
         if @UssdCode = '*0*3*3#'
         begin
            -- Next Step #. Backup to UP MENU
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};paycart-$del,lesswletcart#' , /*'*0*3*3#'*/ @UssdCode ) AS '@data',
	                   @index AS '@order',
	                   N'⤴️ بازگشت' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      end 
	      -- اگر از فرم ورود به حساب کاربری وارد شویم
	      --else if @UssdCode in ( '*1*4*5#' )
	      --begin
	      --   -- Next Step #. Backup to UP MENU
	      --   -- Dynamic
	      --   SET @X = (
	      --      SELECT dbo.STR_FRMT_U('./{0};paycart-$del,lesswletcart#' , /*'*0*3*3#'*/ @UssdCode ) AS '@data',
	      --             @index AS '@order',
	      --             N'⤴️ بازگشت' AS "text()"
	      --         FOR XML PATH('InlineKeyboardButton')
	      --   );
	      --   SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      --   SET @index += 1;
	      --end 
	   END 
	   ELSE IF @CmndText IN ('lessconfwlet')
	   BEGIN
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};paywlet-{1}$del,lessaddwlet#' , '*0*3*3#,' + CAST(@OrdrCode AS VARCHAR(30)))  AS '@data',
                   @index AS '@order',
                   N'🔺 پرداخت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;         
         
         -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lesswletcart' , '*0*3*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessinfowlet' )
	   BEGIN
	      SELECT @ConfStat = os.CONF_STAT,
	             @ConfDate = os.CONF_DATE,
	             @OrdrCode = os.ORDR_CODE
	        FROM dbo.Order_State os 
	       WHERE os.CODE = @OdstCode;
	      IF @ConfStat = '003'
	      BEGIN
            -- Next Step #. حذف کردن رسید پرداخت
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};delwletcart-{1}$del,lesswletcart#', '*0*3*3#' + ',' + CAST(@OdstCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'❌ حذف کردن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END

         -- اگر برای سفارش ردیف پرداختی / تخفیف / رسید پرداخت زده شده باشد
	      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001', '002', '005'))
	      BEGIN 
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lessinfocart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)))  AS '@data',
                      @index AS '@order',
                      N'👓 مشاهده اطلاعات فاکتور' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- اگر سفارش در حالت تسویه حساب یاشد
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND ISNULL(o.DEBT_DNRM, 0) = 0)
	      BEGIN
	         -- Next Step #. Recipt Pay Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};finalcart-{1}$del,lessfinlcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⚡️ پایان سفارش' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
         
         -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lesswletcart#' , '*0*3*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessrcptcart' ) 
	   BEGIN
	      -- بررسی اینکه آیا ما رکوردی برای کارت هدیه مشتری داریم یا خیر
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Order_State a
	          WHERE a.ORDR_CODE = @OrdrCode
	            AND a.AMNT_TYPE = '005'
	      )
	      BEGIN	         
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};rcptcart-{1}$lessinforcpt#', '*0*3*4#' + ',' + CAST(a.CODE AS varchar(30))) AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY a.STAT_DATE ) AS '@order',                      
                      CASE a.CONF_STAT WHEN '001' THEN N'⛔️ ' WHEN '002' THEN N'✅ ' WHEN '003' THEN N'⌛️ ' END + ISNULL(a.STAT_DESC, N'ارسال شده از سمت مشتری') AS "text()"
                 FROM dbo.Order_State a
                WHERE a.ORDR_CODE = @OrdrCode
                  AND a.AMNT_TYPE = '005'
                  AND ((a.FILE_TYPE in ('002', '004') AND a.FILE_ID IS NOT NULL) OR a.FILE_TYPE = '001')
                ORDER BY a.STAT_DATE
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
            SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END 
         
         IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '005' AND os.CONF_STAT = '003')
         BEGIN
            -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT '@/FRST_PAGE_F;loadrcpt-$#' AS '@data',
                      @index AS '@order',
                      N'💡 درخواست تایید رسید' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         
         -- اگر برای سفارش ردیف پرداختی / تخفیف / رسید پرداخت زده شده باشد
	      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001', '002', '005'))
	      BEGIN 
	         -- Next Step #. Backup to UP MENU
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lessinfocart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)))  AS '@data',
                      @index AS '@order',
                      N'👓 مشاهده اطلاعات فاکتور' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- اگر سفارش در حالت تسویه حساب یاشد
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND ISNULL(o.DEBT_DNRM, 0) = 0)
	      BEGIN
	         -- Next Step #. Recipt Pay Card
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};finalcart-{1}$del,lessfinlcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⚡️ پایان سفارش' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessckotcart#' , '*0*3#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessinforcpt' )
	   BEGIN
	      SELECT @ConfStat = os.CONF_STAT,
	             @ConfDate = os.CONF_DATE,
	             @OrdrCode = os.ORDR_CODE
	        FROM dbo.Order_State os 
	       WHERE os.CODE = @OdstCode;
	      IF @ConfStat = '003'
	      BEGIN
            -- Next Step #. حذف کردن رسید پرداخت
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};delrcpt-{1}$del,lessrcptcart#', '*0*3*4#' + ',' + CAST(@OdstCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'❌ حذف کردن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
         
         -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};paycart-{1}$del,lessrcptcart#' , '*0*3*4#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessshipcart' )
	   BEGIN
	      -- Next Step #. Delivery in Store Shop
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lessstorcart#' , @UssdCode + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'🏃🛍  تحویل در محل فروشگاه' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. Delivery in at home
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lessinctcart#' , @UssdCode + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'🏡 تحویل در محل شما ( درون شهری )' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. Deleivry in at your city
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lessotctcart#' , @UssdCode + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'🚚 تحویل به باربری ( برون شهری )' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Next Step #. Deleivry in at your city
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lesspostcart#' , @UssdCode + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'✈️ تحویل به اداره پست ( کشوری )' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- بررسی اینکه وضعیت درخواست به چه صورتی می باشد
	      SELECT @OrdrStat = o.ORDR_STAT
	        FROM dbo.[Order] o
	       WHERE o.CODE = @OrdrCode;
	      -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};showcart-{1}$del,{2}#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) + ',' + CASE @OrdrStat WHEN '001' THEN 'lessinfoinvc' ELSE 'lesshistcart' END ) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lesstarfcart' ) 
	   BEGIN
	      -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$del,lesshistcart#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lessstorcart', 'lessinctcart', 'lessotctcart', 'lesspostcart', 'moreinctcart', 'moreotctcart', 'morepostcart' )
	   BEGIN
	      IF @CmndText IN ('lessinctcart', 'lessotctcart', 'lesspostcart')
	      BEGIN
	         SET @X = (
               SELECT @ChatID AS '@chatid',
                      @Rbid AS '@rbid',
                      '008' AS '@actntype',
                      '*0*5#' AS '@ussdcode',
                      'slctloc4ordr' AS '@cmndtext',
                      @OrdrCode AS '@parmtext',
                      'del,' + @CmndText AS '@postexec',
                      '' as '@trgrtext',
                      'Show All Post Address & Location For Select' AS '@actndesc'
                  FOR XML PATH('Service')
            );            
            EXEC dbo.SAVE_SRBT_P @X = @X, -- xml
                   @XRet = @X output -- xml
            
            SET @X = @X.query('//InlineKeyboardButton');
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
            SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END 
	      
	      IF @CmndText IN ( 'moreinctcart', 'moreotctcart', 'lessstorcart', 'morepostcart' )
	      BEGIN
	         -- Next Step #. Backup to UP MENU
            -- Static
            SET @X = (
               SELECT --dbo.STR_FRMT_U('./{0};howshipping-{1}$del,{2}#' , '*0*5#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) + ',' + 'less' + SUBSTRING(@CmndText, 5, LEN(@CmndText)))  AS '@data',
                      dbo.STR_FRMT_U('./{0};showcart-{1}$del,lessinfoinvc#' , '*0#' + ',' + CAST(@OrdrCode AS NVARCHAR(50)) )  AS '@data',
                      @index AS '@order',
                      N'⤴️ بازگشت' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      ELSE 
	      BEGIN
	         -- Next Step #. Backup to UP MENU
	         -- Static
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};howshipping-{1}$del,lessshipcart#' , '*0*5#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'⤴️ بازگشت' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	   END
	   ELSE IF @CmndText IN ( 'lessisrvshop' )
	   BEGIN
	      -- Static
	      SET @X = (
	         SELECT './*0#;buyshop-$lessbuyshop#' AS '@data',
	                @index AS '@order',
	                N'🛍 خرید های من' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- اگر مشتری محصولی را به صورت علاقه مندی های خود اضافه کرده باشد
	      IF EXISTS(SELECT * FROM dbo.Service_Robot_Product_Like pl WHERE pl.SRBT_ROBO_RBID = @Rbid AND pl.CHAT_ID = @Chatid AND pl.STAT = '002')
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;likeprod-$lesslikeprod#' AS '@data',
                      @index AS '@order',
                      N'❤️ علاقه مندی ها' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;            
	      END 
	      
	      -- اگر مشتری اطلاع رسانی تخفیفات محصولات را برای خود فعال کرده باشد
	      IF EXISTS(SELECT * FROM dbo.Service_Robot_Product_Amazing_Notification an WHERE an.SRBT_ROBO_RBID = @Rbid AND an.CHAT_ID = @Chatid AND an.STAT = '002')
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;amaznoti-$lessamaznoti#' AS '@data',
                      @index AS '@order',
                      N'🔔 اطلاع رسانی تخفیفات' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;            
	      END 
	      
	      -- امتیاز شما
	      
	      -- دعوتی های مشتری
	      IF EXISTS(SELECT * FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.REF_CHAT_ID = @Chatid)
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;invtfrnd-$lessinvtfrnd#' AS '@data',
                      @index AS '@order',
                      N'👥 دعوتی من' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;            
	      END 
	      
	      -- کارت های تخفیف ارائه شده به مشتری
	      IF EXISTS(SELECT * FROM dbo.Service_Robot_Discount_Card dc WHERE dc.SRBT_ROBO_RBID = @Rbid AND dc.CHAT_ID = @Chatid)
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;listdsctcard-$lessdsctcard#' AS '@data',
                      @index AS '@order',
                      N'💸 کارت های تخفیف' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;            
	      END 
	      
	      -- کارت های هدیه
	      IF EXISTS(SELECT * FROM dbo.Service_Robot_Gift_Card gc WHERE gc.SRBT_ROBO_RBID = @Rbid AND gc.CHAT_ID = @Chatid)
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;listgiftcard-$lessgiftcard#' AS '@data',
                      @index AS '@order',
                      N'💳 کارت های هدیه' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;            
	      END 
	      
	      -- کیف پول
	      IF EXISTS(SELECT * FROM dbo.Wallet w WHERE w.SRBT_ROBO_RBID = @Rbid AND w.CHAT_ID = @Chatid AND w.WLET_TYPE = '002' /* Cash Wallet */ AND EXISTS(SELECT * FROM dbo.Wallet_Detail wd WHERE w.CODE = wd.WLET_CODE))
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;wlettran-$lesswlettran#' AS '@data',
                      @index AS '@order',
                      N'💎 کیف پول' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;            
	      END 	      
	   END
	   ELSE IF @CmndText IN ( 'allbuyshop' )
	   BEGIN
	      SELECT @FromDate = CASE id WHEN 1 THEN CONVERT(DATE, Item) ELSE @FromDate END,
	             @ToDate   = CASE id WHEN 2 THEN CONVERT(DATE, Item) ELSE @ToDate END
	        FROM dbo.SplitString(@ParamsText, ',');
	      
	      -- Dynamic
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};{2}-{1}$lesshistcart#', 
                     @UssdCode + ',' + 
                     CAST(o.CODE AS varchar(30)) + ',' + 
                     CASE WHEN EXISTS(
                                  SELECT osh.ORDR_CODE
                                    FROM dbo.Order_Step_History osh
                                   WHERE o.CODE = osh.ORDR_CODE
                                     AND osh.ORDR_STAT IN ( '004', '009' )
                                   GROUP BY osh.ORDR_CODE
                                  HAVING COUNT(DISTINCT osh.ORDR_STAT) = 1) THEN 'historycart'
                          ELSE 'infocart'
                     END 
                   ) AS '@data',
                   ROW_NUMBER() OVER ( ORDER BY o.END_DATE DESC ) AS '@order',                      
                   N'🛍 شماره فاکتور ' + CAST(o.ORDR_TYPE_NUMB AS VARCHAR(30)) + N' 📆 تاریخ ' + dbo.GET_MTOS_U(o.END_DATE) AS "text()"
              FROM dbo.[Order] o
             WHERE o.SRBT_ROBO_RBID = @Rbid
               AND o.CHAT_ID = @Chatid
               AND o.ORDR_TYPE = '004' /* سفارش محصول */
               AND CAST(o.END_DATE AS DATE) BETWEEN @FromDate AND @ToDate
               AND EXISTS(
                   SELECT osh.ORDR_CODE
                     FROM dbo.Order_Step_History osh
                    WHERE o.CODE = osh.ORDR_CODE
                      AND osh.ORDR_STAT IN ( '004', '009' )
                    GROUP BY osh.ORDR_CODE
                   HAVING COUNT(DISTINCT osh.ORDR_STAT) IN ( 1, 2 )
                   )
             ORDER BY o.END_DATE DESC 
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	   END 
	   ELSE IF @CmndText IN ( 'lessbuyshop' ) 
	   BEGIN
	      -- سفارش هایی که مشتری انجام داده و بسته را کامل تحویل گرفته
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.SRBT_ROBO_RBID = @Rbid AND o.CHAT_ID = @Chatid AND o.ORDR_TYPE = '004' AND EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE o.CODE = osh.ORDR_CODE AND osh.ORDR_STAT IN ('004' /* پرداخت سفارش */, '009' /* تحویل بسته */)))
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;buyshop-$del,lesshbuyshop#' AS '@data',
                      @index AS '@order',
                      N'📚 خرید های اتمام شده' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- سفارش هایی که داده شده ولی به دست مشتری نرسیده
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.SRBT_ROBO_RBID = @Rbid AND o.CHAT_ID = @Chatid AND o.ORDR_TYPE = '004' AND EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE o.CODE = osh.ORDR_CODE AND osh.ORDR_STAT IN ('004' /* پرداخت سفارش */) ) AND NOT EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE osh.ORDR_CODE = o.CODE AND (osh.ORDR_STAT = '009' /* تحویل بسته */)))
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;buyshop-$del,lessubuyshop#' AS '@data',
                      @index AS '@order',
                      N'🛍 خرید های جاری' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END
	      
	      -- در سفارشی برای فروش داشته باشیم
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.SRBT_ROBO_RBID = @Rbid AND o.CHAT_ID = @Chatid AND o.ORDR_TYPE = '004' AND o.ORDR_STAT = '001')
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './*0#;showcart-$del,lessinfoinvc#' AS '@data',
                      @index AS '@order',
                      N'💎 سفارش جاری' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END
	      
	      -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT './*0#;noaction-$del#<>' AS '@data',
                   @index AS '@order',
                   N'⤴️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;	      
	   END 
	   ELSE IF @CmndText IN ( 'lesshbuyshop' )
	   BEGIN
	      -- Next Step #. Show Discount Card
         -- Dynamic
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};historycart-{1}$lesshistcart#', '*0#' + ',' + CAST(o.CODE AS varchar(30))) AS '@data',
                   ROW_NUMBER() OVER ( ORDER BY o.END_DATE DESC ) AS '@order',                      
                   N'🛍 شماره فاکتور ' + CAST(o.ORDR_TYPE_NUMB AS VARCHAR(30)) + N' 📆 تاریخ ' + dbo.GET_MTOS_U(o.END_DATE) AS "text()"
              FROM dbo.[Order] o
             WHERE o.SRBT_ROBO_RBID = @Rbid
               AND o.CHAT_ID = @Chatid
               AND o.ORDR_TYPE = '004' /* سفارش محصول */
               AND EXISTS(
                      SELECT osh.ORDR_CODE
                        FROM dbo.Order_Step_History osh
                       WHERE o.CODE = osh.ORDR_CODE
                         AND osh.ORDR_STAT IN ( '004', '009' )
                       GROUP BY osh.ORDR_CODE
                      HAVING COUNT(DISTINCT osh.ORDR_STAT) = 2
                   )
             ORDER BY o.END_DATE DESC 
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
         
         -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT './*0#;buyshop-$del,lessbuyshop#' AS '@data',
                   @index AS '@order',
                   N'⤴️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;	      
	   END
	   ELSE IF @CmndText IN ( 'lessubuyshop' )
	   BEGIN
         -- Dynamic
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};infocart-{1}$lesshistcart#', '*0#' + ',' + CAST(o.CODE AS varchar(30))) AS '@data',
                   ROW_NUMBER() OVER ( ORDER BY o.END_DATE DESC ) AS '@order',                      
                   N'🛍 شماره فاکتور ' + CAST(o.ORDR_TYPE_NUMB AS VARCHAR(30)) + N' 📆 تاریخ ' + dbo.GET_MTOS_U(o.END_DATE) AS "text()"
              FROM dbo.[Order] o
             WHERE o.SRBT_ROBO_RBID = @Rbid
               AND o.CHAT_ID = @Chatid
               AND o.ORDR_TYPE = '004' /* سفارش محصول */
               AND EXISTS(
                   SELECT osh.ORDR_CODE
                     FROM dbo.Order_Step_History osh
                    WHERE o.CODE = osh.ORDR_CODE
                      AND osh.ORDR_STAT IN ( '004', '009' )
                    GROUP BY osh.ORDR_CODE
                   HAVING COUNT(DISTINCT osh.ORDR_STAT) = 1
                   )
             ORDER BY o.END_DATE DESC 
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
         
         -- Next Step #. Backup to UP MENU
         -- Static
         SET @X = (
            SELECT './*0#;buyshop-$del,lessbuyshop#' AS '@data',
                   @index AS '@order',
                   N'⤴️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;	      
	   END 
	   ELSE IF @CmndText IN ( 'notinewordrtoacnt' ) /* منوهای اطلاع رسانی به حسابدار جهت ثبت سفارش جدید */
	   BEGIN
	      IF NOT EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE osh.ORDR_CODE = @OrdrCode AND osh.ORDR_STAT = '012' /* ثبت در سیستم حسابداری */)
	      BEGIN
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./*0#;acntman::saveordr-{0}$del#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'💾 ثبت در سیستم حسابداری' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
	   END 
	   ELSE IF @CmndText IN ( 'notinewordrtostor' ) /* منوهای اطلاع رسانی به انباردار جهت ثبت سفارش جدید */
	   BEGIN
	      IF NOT EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE osh.ORDR_CODE = @OrdrCode AND osh.ORDR_STAT = '013' /* انباردار سفارش را دریافت کرد */)
	      BEGIN
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./*0#;storman::doordr-{0}$del,notinewordrtostor#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'😃✋ من سفارش را انجام میدهم' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            GOTO L$EndSP;
         END
         
         IF NOT EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE osh.ORDR_CODE = @OrdrCode AND osh.ORDR_STAT = '014' /* جمع آوری و بسته بندی اقلام سفارش */)
	      BEGIN
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./*0#;storman::colcpackordr-{0}$del,notinewordrtostor#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'📦 جمع آوری و بسته بندی اقلام سفارش' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            GOTO L$EndSP;
         END
         
         IF NOT EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE osh.ORDR_CODE = @OrdrCode AND osh.ORDR_STAT = '015' /* خروج بسته و تحویل به سفیر */)
	      BEGIN
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./*0#;storman::exitdelvordr-{0}$del,notinewordrtostor#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'🚚 خروج بسته و تحویل سفارش' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
	   END 
	   ELSE IF @CmndText IN ( 'notinewordrtocori' ) /* منوی اطلاع رسانی به سفیران جهت تحویل سفارش */
	   BEGIN
	      -- Static
         --SET @X = (
         --   SELECT dbo.STR_FRMT_U('./*0#;coriman::infosorctrgtloc-{0}$del,notinewordrtocori#', CAST(@OrdrCode as VARCHAR(30))) AS '@data',
         --          @index AS '@order',
         --          N'📍 جزئیات آدرس' AS "text()"
         --      FOR XML PATH('InlineKeyboardButton')
         --);
         --SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         --SET @index += 1;
         
	      IF NOT EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE osh.ORDR_CODE = @OrdrCode AND osh.ORDR_STAT = '006' /* انتخاب سفیر برای ارسال بسته */)
	      BEGIN
	         -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./*0#;coriman::takeordr-{0}$del,notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'😀🖐 من سفارش را میبرم' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            GOTO L$EndSP;
	      END 
	      
	      IF NOT EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE osh.ORDR_CODE = @OrdrCode AND osh.ORDR_STAT = '007' /* دریافت بسته سفارش از مبدا */)
	      BEGIN
	         -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./*0#;coriman::getordr-{0}$notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'📦 دریافت بسته سفارش' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            GOTO L$EndSP;
	      END 
	      
	      IF NOT EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE osh.ORDR_CODE = @OrdrCode AND osh.ORDR_STAT = '008' /* تحویل بسته سفارش */)
	      BEGIN
	         IF @ParamsText LIKE '%,getListPric%'
	         BEGIN
	            -- Dynamic
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./*0#;coriman::ordrdelvamntfee-{0},getListPric,0$del,notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                         @index AS '@order',
                         N'⭐️ ارسال رایگان' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
               
               -- اگر تا به الان مبلغی برای هزینه پیک ثبت نشده باشد
               --IF NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.ORDR_TYPE = '023' AND o.ARCH_STAT = '002')
               BEGIN
                  -- Dynamic
                  SET @X = (
                     SELECT dbo.STR_FRMT_U('./*0#;coriman::ordrdelvamntfee-{0},getListPric,5000$del,notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                            @index AS '@order',
                            N'➕ 500 تومان' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                  );
                  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
                  SET @index += 1;
                  
                  -- Dynamic
                  SET @X = (
                     SELECT dbo.STR_FRMT_U('./*0#;coriman::ordrdelvamntfee-{0},getListPric,10000$del,notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                            @index AS '@order',
                            N'➕ 1,000 تومان' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                  );
                  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
                  SET @index += 1;
                  
                  -- Dynamic
                  SET @X = (
                     SELECT dbo.STR_FRMT_U('./*0#;coriman::ordrdelvamntfee-{0},getListPric,50000$del,notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                            @index AS '@order',
                            N'➕ 5,000 تومان' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                  );
                  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
                  SET @index += 1;
                  
                  -- Dynamic
                  SET @X = (
                     SELECT dbo.STR_FRMT_U('./*0#;coriman::ordrdelvamntfee-{0},getListPric,100000$del,notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                            @index AS '@order',
                            N'➕ 10,000 تومان' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                  );
                  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
                  SET @index += 1;
               END 

               -- Next Step #. Backup to UP MENU
               -- Static
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./*0#;coriman::ordrdelvfee-{0}$del,notinewordrtocori#', @OrdrCode) AS '@data',
                         @index AS '@order',
                         N'⤴️ بازگشت' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;               
	         END 
	         ELSE IF ISNULL(@ParamsText, '') NOT LIKE '%,%'/* منوی اولیه */
	         BEGIN 
	            -- Dynamic
               SET @X = (
                  SELECT dbo.STR_FRMT_U('!./*0#;coriman::ordrdelvfee-{0},getListPric$del,notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                         @index AS '@order',
                         N'💵 مبلغ حق الزحمه' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
               
               IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.ORDR_CODE = @OrdrCode AND o.ORDR_TYPE = '023' /* درخواست هزینه حق الزحمه ارسال */)
               BEGIN
                  -- Dynamic
                  SET @X = (
                     SELECT dbo.STR_FRMT_U('./*0#;coriman::delvpackordr-{0}$notinewordrtocori#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                            @index AS '@order',
                            N'👍 تحویل بسته سفارش' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                  );
                  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
                  SET @index += 1;
               END 
            END 
            GOTO L$EndSP;
	      END 	      
	   END 
	   ELSE IF @CmndText IN ( 'notinotakeordrtocori' ) /* منوی اطلاع رسانی به سفیران بدون اعتبار جهت دریافت سفارشات */
	   BEGIN
	      -- Static
         SET @X = (
            SELECT './*0*3*3#;addamntwlet-howinccreditwlet$del,lessaddwlet#' AS '@data',
                   @index AS '@order',
                   N'💎 کیف پول' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT './*0#;coriman::exitjob-$del,lessexjbcori#' AS '@data',
                   @index AS '@order',
                   N'🙏😔 عدم همکاری و قطع ارتباط' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'custgetordr' ) /* زمانی که مشتری صحت دریافت سفارش را تایید میکند */
	   BEGIN
	      -- اگر مشتری درب فروشگاه سفارش را تحویل بگیرد
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND o.HOW_SHIP = '001' /* تحویل درب فروشگاه */)
	      BEGIN
	         -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./*0#;custman::okgetordr-{0}$del#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'💾 سفارش را تحویل گرفتم' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      ELSE
	      BEGIN
	         IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND o.DEBT_DNRM = 0)
	         begin
	            -- Dynamic
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./*0#;custman::okgetordr-{0},free$del#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                         @index AS '@order',
                         N'⭐️ دریافت رایگان' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
            END 
            ELSE 
            BEGIN
	            -- Dynamic
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./*0#;custman::okgetordr-{0},cashpay$#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                         @index AS '@order',
                         N'💵 پرداخت نقدی' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
               
               -- Dynamic
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./*0#;noaction-{0},onlinepay$pay#<>', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                         @index AS '@order',
                         N'🌐 پرداخت آنلاین' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               SET @index += 1;
               
               IF EXISTS(SELECT * FROM dbo.Wallet w, dbo.[Order] o WHERE w.SRBT_ROBO_RBID = o.SRBT_ROBO_RBID AND w.CHAT_ID = o.CHAT_ID AND w.WLET_TYPE = '002' /* Cash Wallet */ AND o.CODE = @OrdrCode AND o.DEBT_DNRM <= ISNULL(w.AMNT_DNRM, 0))
               BEGIN
                  -- Dynamic
                  SET @X = (
                     SELECT dbo.STR_FRMT_U('./*0#;custman::okgetordr-{0},walletcashpay$del#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                            @index AS '@order',
                            N'💵 پرداخت از کیف پول نقدی' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                  );
                  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
                  SET @index += 1;
               END 
               
               IF EXISTS(SELECT * FROM dbo.Wallet w, dbo.[Order] o WHERE w.SRBT_ROBO_RBID = o.SRBT_ROBO_RBID AND w.CHAT_ID = o.CHAT_ID AND w.WLET_TYPE = '001' /* Credit Wallet */ AND o.CODE = @OrdrCode AND o.DEBT_DNRM <= ISNULL(w.AMNT_DNRM, 0))
               BEGIN
                  -- Dynamic
                  SET @X = (
                     SELECT dbo.STR_FRMT_U('./*0#;custman::okgetordr-{0},walletcreditpay$del#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                            @index AS '@order',
                            N'💳 پرداخت از کیف پول اعتباری' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                  );
                  SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
                  SET @index += 1;
               END 
               
               -- Dynamic
               --SET @X = (
               --   SELECT dbo.STR_FRMT_U('./*0#;custman::okgetordr-{0}$del#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
               --          @index AS '@order',
               --          N'🤔 من مبلغ دیگری پرداخت کرده ام' AS "text()"
               --      FOR XML PATH('InlineKeyboardButton')
               --);
               --SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
               --SET @index += 1;
            END 
            
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./*0#;custman::okgetordr-{0}$del#', CAST(@OrdrCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'😡 عدم تحویل سفارش' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	   END 
	   ELSE IF @CmndText IN ( 'lesssortdeal', 'lesssortbrnd', 'lesssortprodbrnd' )
	   BEGIN
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'splh' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'💰🔺 قیمت از ارزان به گران' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'sphl' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'💰🔻 قیمت از گران به ارزان' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'sdlh' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'%🔺 تخفیف از کم به زیاد' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'sdhl' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'%🔻 تخفیف از زیاد به کم' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'srno' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'⏰🔺 زمان انتشار از جدید به قدیم' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'sron' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'⏰🔻 زمان انتشار از قدیم به جدید' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'svml' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'👓🔻 بازدید از زیاد به کم' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'svlm' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'👓🔺 بازدید از کم به زیاد' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'sfml' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'❤️🔻 محبوبیت از زیاد به کم' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'sflm' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'❤️🔺 محبوبیت از کم به زیاد' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'sbml' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'🤑🔻 پر فروش ترین از زیاد به کم' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'sblm' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'🤑🔺 پر فروش ترین از کم به زیاد' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'stfs' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'🚚🔻 زمان ارسال / تحویل از سریع به کند' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'stsf' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'🚚🔺 زمان ارسال / تحویل از کند به سریع' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'spat' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'🚚🔻 موجود کالا از موجود به ناموجود' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @TarfCode = (
            SELECT CASE WHEN id IN (1) THEN Item + ','
                        WHEN id IN (2) THEN 'spaf' + ','
                        WHEN id IN (3) THEN Item + ','
                        ELSE Item
                   END
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::sort-{Param}$del,{1}#', '{Param}', @TarfCode), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals,' WHEN 'lesssortbrnd' THEN 'brandswar,' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText ) AS '@data',
                   @index AS '@order',
                   N'🚚🔺 موجودی کالا از ناموجود به موجود' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT REPLACE('./*0#;{0}::sort-1,n,n,t$del#', '{0}', CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals' WHEN 'lesssortbrnd' THEN 'brandswar' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'📚 بدون مرتب سازی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::show-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lesssortdeal' THEN 'daydeals' WHEN 'lesssortbrnd' THEN 'brandswar' WHEN 'lesssortprodbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 	   
	   ELSE IF @CmndText IN ( 'lessadvndeal', 'lessadvnbrnd' )
	   BEGIN
	      -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::category-{Param}$del,{1}#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvndeal' THEN 'daydeals,lessadvgdeal' WHEN 'lessadvnbrnd' THEN 'brandswar::showinfobrand,lessadvgbrnd' END) AS '@data',
                   @index AS '@order',
                   N'🗄 دسته بندی کالاها' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::type-{Param}$del,{1}#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvndeal' THEN 'daydeals,lessadvtdeal' WHEN 'lessadvnbrnd' THEN 'brandswar::showinfobrand,lessadvtbrnd' END) AS '@data',
                   @index AS '@order',
                   N'🔖 نوع معاملات' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::price-{Param}$del,{1}#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvndeal' THEN 'daydeals,lessadvpdeal' WHEN 'lessadvnbrnd' THEN 'brandswar::showinfobrand,lessadvpbrnd' END) AS '@data',
                   @index AS '@order',
                   N'💰 مبالغ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::discount-{Param}$del,{1}#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvndeal' THEN 'daydeals,lessadvddeal' WHEN 'lessadvnbrnd' THEN 'brandswar::showinfobrand,lessadvdbrnd' END) AS '@data',
                   @index AS '@order',
                   N'% تخفیفات' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::customerreview-{Param}$del,{1}#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvndeal' THEN 'daydeals,lessadvcdeal' WHEN 'lessadvnbrnd' THEN 'brandswar::showinfobrand,lessadvcbrnd' END) AS '@data',
                   @index AS '@order',
                   N'👥 نظرات مشتریان' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::show-{Param}$del#', '{Param}', '1,n,n,t'), CASE @CmndText WHEN 'lessadvndeal' THEN 'daydeals' when 'lessadvnbrnd' THEN 'brandswar::showinfobrand' END ) AS '@data',
                   @index AS '@order',
                   N'🎲 بدون فیلتر' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;

         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::show-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvndeal' THEN 'daydeals' when 'lessadvnbrnd' THEN 'brandswar::showinfobrand' END ) AS '@data',
                   @index AS '@order',
                   N'📊 نمایش خروجی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lessadvtdeal', 'lessadvtbrnd' )
	   BEGIN
	      SET @TarfCode = (
            SELECT CASE WHEN id IN (1, 2) THEN Item + ',' 
                        WHEN id = 3 AND Item LIKE '%t%' THEN (SELECT CASE SUBSTRING(Item, 1, 1) WHEN 't' THEN 't{0}*' ELSE Item + '*' END FROM dbo.SplitString(Item, '*') WHERE LEN(Item) != 0 FOR XML PATH('')) + ','
                        WHEN id = 3 AND Item NOT LIKE '%t%' AND Item != 'n' THEN Item + '*t{0},' 
                        WHEN id = 3 AND Item NOT LIKE '%t%' AND Item = 'n' THEN 't{0},' 
                        WHEN id = 4 THEN Item
                   END 
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::type-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '000')), CASE @CmndText WHEN 'lessadvtdeal' THEN 'daydeals,' WHEN 'lessadvtbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'💡 فروش عادی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::type-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '001')), CASE @CmndText WHEN 'lessadvtdeal' THEN 'daydeals,' WHEN 'lessadvtbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'⏱ فروش شگفت انگیز' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::type-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '002')), CASE @CmndText WHEN 'lessadvtdeal' THEN 'daydeals,' WHEN 'lessadvtbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'💥 فروش ویژه' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::type-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '003')), CASE @CmndText WHEN 'lessadvtdeal' THEN 'daydeals,' WHEN 'lessadvtbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'🎁 فروش همراه با هدیه' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::show-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvtdeal' THEN 'daydeals' WHEN 'lessadvtbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'📊 نمایش خروجی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::type-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '000')), CASE @CmndText WHEN 'lessadvtdeal' THEN 'daydeals,' WHEN 'lessadvtbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'🎲 بدون فیلتر' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvtdeal' THEN 'daydeals' WHEN 'lessadvtbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;	   
	   END
	   ELSE IF @CmndText IN ( 'lessadvpdeal', 'lessadvpbrnd' )
	   BEGIN
	      SET @TarfCode = (
            SELECT CASE WHEN id IN (1, 2) THEN Item + ',' 
                        WHEN id = 3 AND Item LIKE '%p%' THEN (SELECT CASE SUBSTRING(Item, 1, 1) WHEN 'p' THEN 'p{0}*' ELSE Item + '*' END FROM dbo.SplitString(Item, '*') WHERE LEN(Item) != 0 FOR XML PATH('')) + ','
                        WHEN id = 3 AND Item NOT LIKE '%p%' AND Item != 'n' THEN Item + '*p{0},' 
                        WHEN id = 3 AND Item NOT LIKE '%p%' AND Item = 'n' THEN 'p{0},' 
                        WHEN id = 4 THEN Item
                   END 
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::price-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '001')), CASE @CmndText WHEN 'lessadvpdeal' THEN 'daydeals,' WHEN 'lessadvpbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'💰 زیر 25 هزار تومان' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::price-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '002')), CASE @CmndText WHEN 'lessadvpdeal' THEN 'daydeals,' WHEN 'lessadvpbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'💰 از 25 تا 50 هزار تومان' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::price-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '003')), CASE @CmndText WHEN 'lessadvpdeal' THEN 'daydeals,' WHEN 'lessadvpbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'💰 از 50 تا 100 هزار تومان' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::price-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '004')), CASE @CmndText WHEN 'lessadvpdeal' THEN 'daydeals,' WHEN 'lessadvpbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'💰 از 100 تا 200 هزار تومان' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::price-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '005')), CASE @CmndText WHEN 'lessadvpdeal' THEN 'daydeals,' WHEN 'lessadvpbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'💰 بالای 200 هزار تومان' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::show-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvpdeal' THEN 'daydeals' WHEN 'lessadvpbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'📊 نمایش خروجی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::price-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '000')), CASE @CmndText WHEN 'lessadvpdeal' THEN 'daydeals,' WHEN 'lessadvpbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'🎲 بدون فیلتر' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvpdeal' THEN 'daydeals' WHEN 'lessadvpbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;	   
	   END
	   ELSE IF @CmndText IN ( 'lessadvddeal', 'lessadvdbrnd' )
	   BEGIN
	      SET @TarfCode = (
            SELECT CASE WHEN id IN (1, 2) THEN Item + ',' 
                        WHEN id = 3 AND Item LIKE '%d%' THEN (SELECT CASE SUBSTRING(Item, 1, 1) WHEN 'd' THEN 'd{0}*' ELSE Item + '*' END FROM dbo.SplitString(Item, '*') WHERE LEN(Item) != 0 FOR XML PATH('')) + ','
                        WHEN id = 3 AND Item NOT LIKE '%d%' AND Item != 'n' THEN Item + '*d{0},' 
                        WHEN id = 3 AND Item NOT LIKE '%d%' AND Item = 'n' THEN 'd{0},' 
                        WHEN id = 4 THEN Item
                   END 
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::discount-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '001')), CASE @CmndText WHEN 'lessadvddeal' THEN 'daydeals,' WHEN 'lessadvdbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'✨ بالای 10%' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::discount-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '002')), CASE @CmndText WHEN 'lessadvddeal' THEN 'daydeals,' WHEN 'lessadvdbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'✨ بالای 25%' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::discount-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '003')), CASE @CmndText WHEN 'lessadvddeal' THEN 'daydeals,' WHEN 'lessadvdbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'✨ بالای 50%' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::discount-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '004')), CASE @CmndText WHEN 'lessadvddeal' THEN 'daydeals,' WHEN 'lessadvdbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'✨ بالای 70%' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::show-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvddeal' THEN 'daydeals' WHEN 'lessadvdbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'📊 نمایش خروجی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::discount-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '000')), CASE @CmndText WHEN 'lessadvddeal' THEN 'daydeals,' WHEN 'lessadvdbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'🎲 بدون فیلتر' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvddeal' THEN 'daydeals' WHEN 'lessadvdbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;	   
	   END
	   ELSE IF @CmndText IN ( 'lessadvcdeal', 'lessadvcbrnd' )
	   BEGIN
	      SET @TarfCode = (
            SELECT CASE WHEN id IN (1, 2) THEN Item + ',' 
                        WHEN id = 3 AND Item LIKE '%c%' THEN (SELECT CASE SUBSTRING(Item, 1, 1) WHEN 'c' THEN 'c{0}*' ELSE Item + '*' END FROM dbo.SplitString(Item, '*') WHERE LEN(Item) != 0 FOR XML PATH('')) + ','
                        WHEN id = 3 AND Item NOT LIKE '%c%' AND Item != 'n' THEN Item + '*c{0},' 
                        WHEN id = 3 AND Item NOT LIKE '%c%' AND Item = 'n' THEN 'c{0},' 
                        WHEN id = 4 THEN Item
                   END 
              FROM dbo.SplitString(@ParamsText, ',')
               FOR XML PATH('')
         );
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::customerreview-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '1')), CASE @CmndText WHEN 'lessadvcdeal' THEN 'daydeals,' WHEN 'lessadvcbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::customerreview-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '2')), CASE @CmndText WHEN 'lessadvcdeal' THEN 'daydeals,' WHEN 'lessadvcbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::customerreview-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '3')), CASE @CmndText WHEN 'lessadvcdeal' THEN 'daydeals,' WHEN 'lessadvcbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::customerreview-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '4')), CASE @CmndText WHEN 'lessadvcdeal' THEN 'daydeals,' WHEN 'lessadvcbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::customerreview-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '5')), CASE @CmndText WHEN 'lessadvcdeal' THEN 'daydeals,' WHEN 'lessadvcbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::show-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvcdeal' THEN 'daydeals' WHEN 'lessadvcbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'📊 نمایش خروجی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance::customerreview-{Param}$del,{1}#', '{Param}', REPLACE(@TarfCode, '{0}', '0')), CASE @CmndText WHEN 'lessadvcdeal' THEN 'daydeals,' WHEN 'lessadvcbrnd' THEN 'brandswar::showinfobrand,' END + @CmndText) AS '@data',
                   @index AS '@order',
                   N'🎲 بدون فیلتر' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U(REPLACE('./*0#;{0}::advance-{Param}$del#', '{Param}', @ParamsText), CASE @CmndText WHEN 'lessadvcdeal' THEN 'daydeals' WHEN 'lessadvcbrnd' THEN 'brandswar::showinfobrand' END) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText in ( 'lessjoingpsl' )
	   BEGIN
	      -- Static
         SET @X = (
            SELECT REPLACE('./' + @UssdCode + ';join::gropsale::accept-{0}$del#', '{0}', @Chatid) AS '@data',
                   @index AS '@order',
                   N'✅ بله' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT REPLACE('./' + @UssdCode + ';join::gropsale::reject-{0}$del#', '{0}', @Chatid) AS '@data',
                   @index AS '@order',
                   N'❌ خیر' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessloctinfo', 'moreloctinfo' )
	   BEGIN
	      -- Static
         SET @X = (
            SELECT REPLACE('!./' + @UssdCode + ';location::update-{0}$del,lessloctinfo#', '{0}', @ParamsText) AS '@data',
                   @index AS '@order',
                   N'✏️ ویرایش آدرس' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT REPLACE('./' + @UssdCode + ';location::del-{0}$del,lessloctinfo#', '{0}', @ParamsText) AS '@data',
                   @index AS '@order',
                   N'❌ حذف آدرس' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
	      IF @CmndText IN ('lessloctinfo')
	      BEGIN 
	         -- Static
            SET @X = (
               SELECT REPLACE('./' + @UssdCode + ';location::select-{0}$del,moreloctinfo#', '{0}', @ParamsText) AS '@data',
                      @index AS '@order',
                      N'🔵 بیشتر' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         ELSE IF @CmndText IN ( 'moreloctinfo' )
         BEGIN
            PRINT 'no more';
         END
         
         -- Static
         SET @X = (
            SELECT './' + @UssdCode + ';location::show-$del#' AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessloctdel' )
	   BEGIN
	      -- Static
         SET @X = (
            SELECT REPLACE('./' + @UssdCode + ';location::del::confirmed-{0}$del#', '{0}', @ParamsText) AS '@data',
                   @index AS '@order',
                   N'✏️ بله' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};location::select-{1}$del,lessloctinfo#', @UssdCode + ',' + CAST(@Index AS VARCHAR(30))) AS '@data',
                   1 AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessbankacnt' )
	   BEGIN
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Service_Robot sr, dbo.Service_Robot_Card_Bank a, dbo.Robot_Card_Bank_Account b
	          WHERE sr.SERV_FILE_NO = a.SRBT_SERV_FILE_NO
	            AND sr.ROBO_RBID = a.SRBT_ROBO_RBID
	            AND a.RCBA_CODE = b.CODE
	            AND b.ROBO_RBID = @Rbid
	            AND sr.CHAT_ID = @Chatid
	            --AND b.ACNT_STAT = '002' -- فعال
	            AND (
                      b.ACNT_TYPE = 
                      CASE 
                           WHEN @UssdCode IN ('*1*4#', '*1*4*2*0#') THEN '003' -- حساب های متفرقه مانند حساب مشتریان
                           WHEN @UssdCode IN ('*3*0#', '*3*0*0*0#') THEN '003' -- حساب های متفرقه برای هزینه پیک
	                        WHEN @UssdCode IN ('*6*0#', '*6*0*0*0#') THEN '002' -- حساب های مدیر فروشگاه
                      END
                   )
	      )
	      BEGIN
	         SET @X = (
	            SELECT './' + @UssdCode + ';bankcard::showinfo-' + CAST(a.CODE AS VARCHAR(30)) + '$del#' AS '@data',
	                   ROW_NUMBER() OVER (ORDER BY b.CARD_NUMB) AS '@order',
	                   /*N'💳 '*/ CASE 
	                                  WHEN b.ORDR_TYPE IN ('004') THEN N'🛒 '
	                                  WHEN b.ORDR_TYPE IN ('013') THEN N'💰 '
	                                  WHEN b.ORDR_TYPE IN ('015') THEN N'💎 '
	                                  WHEN b.ORDR_TYPE IN ('023') THEN N'🚚 '
	                                  WHEN b.ORDR_TYPE IN ('024') AND b.ACNT_TYPE = '003' THEN N'💵 '
	                                  WHEN b.ORDR_TYPE IN ('024') AND b.ACNT_TYPE = '002' THEN N'💸 '
	                             END + CASE b.ACNT_STAT WHEN '001' THEN N'⭕ ' WHEN '002' THEN N'✅ ' END + b.CARD_NUMB_DNRM + N' * ' + b.BANK_NAME  AS "text()"
	              FROM dbo.Service_Robot sr, dbo.Service_Robot_Card_Bank a, dbo.Robot_Card_Bank_Account b
	             WHERE sr.SERV_FILE_NO = a.SRBT_SERV_FILE_NO
	               AND sr.ROBO_RBID = a.SRBT_ROBO_RBID
	               AND a.RCBA_CODE = b.CODE
	               AND b.ROBO_RBID = @Rbid
	               AND sr.CHAT_ID = @Chatid
	               --AND b.ACNT_STAT = '002' -- فعال
	               AND (
	                      b.ACNT_TYPE = 
	                      CASE 
                              WHEN @UssdCode IN ('*1*4#', '*1*4*2*0#') THEN '003' -- حساب های متفرقه مانند حساب مشتریان
                              WHEN @UssdCode IN ('*3*0#', '*3*0*0*0#') THEN '003' -- حساب های متفرقه برای هزینه پیک
	                           WHEN @UssdCode IN ('*6*0#', '*6*0*0*0#') THEN '002' -- حساب های مدیر فروشگاه
                         END
	                   )
	             ORDER BY b.ORDR_TYPE, b.ACNT_STAT DESC 
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END 
	      
	      -- حساب های دریافتنی پورسانت
	      IF @UssdCode IN ( '*1*4#', '*1*4*2*0#', '*3*0#', '*3*0*0*0#' )
	      BEGIN 
	         -- Dynamic
            SET @X = (
               SELECT '!./' + CASE  
                                   WHEN @UssdCode IN ('*1*4#', '*1*4*2*0#') THEN '*1*4*2*0#' 
                                   WHEN @UssdCode IN ('*3*0#', '*3*0*0*0#') THEN '*3*0*0*0#'
                              END + 
                      ';bankcard::new-024$#' AS '@data',
                      @index AS '@order',
                      N'➕ تعریف کارت جدید بابت دریافت پورسانت' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
         
         -- حسابهای دریافتنی هزینه پیک
         IF @UssdCode IN ( '*3*0#', '*3*0*0*0#' ) 
         BEGIN
            -- Dynamic
            SET @X = (
               SELECT '!./' + CASE                                     
                                   WHEN @UssdCode IN ('*3*0#', '*3*0*0*0#') THEN '*3*0*0*0#'
                              END + 
                      ';bankcard::new-023$#' AS '@data',
                      @index AS '@order',
                      N'➕ تعریف کارت جدید بابت درآمد ارسال بسته' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
         
         -- حسابهای دریافتنی فروش آنلاین
         IF @UssdCode IN ( '*6*0#', '*6*0*0*0#' ) 
         BEGIN
            -- Dynamic
            SET @X = (
               SELECT '!./' + CASE 
                                   WHEN @UssdCode IN ('*6*0#', '*6*0*0*0#') THEN '*6*0*0*0#'
                              END + 
                      ';bankcard::new-004$#' AS '@data',
                      @index AS '@order',
                      N'➕ تعریف کارت جدید بابت فروش آنلاین' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            -- Dynamic
            SET @X = (
               SELECT '!./' + CASE 
                                   WHEN @UssdCode IN ('*6*0#', '*6*0*0*0#') THEN '*6*0*0*0#'
                              END + 
                      ';bankcard::new-015$#' AS '@data',
                      @index AS '@order',
                      N'➕ تعریف کارت جدید بابت سپرده مشتریان' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            -- Dynamic
            SET @X = (
               SELECT '!./' + CASE 
                                   WHEN @UssdCode IN ('*6*0#', '*6*0*0*0#') THEN '*6*0*0*0#'
                              END + 
                      ';bankcard::new-017$#' AS '@data',
                      @index AS '@order',
                      N'➕ تعریف کارت جدید بابت پرداخت پورسانت مشتریان' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
	   END 
	   ELSE IF @CmndText IN ( 'lessbkcdinfo' )
	   BEGIN
	      IF EXISTS(SELECT * FROM dbo.Service_Robot_Card_Bank a, dbo.Robot_Card_Bank_Account b WHERE a.RCBA_CODE = b.CODE AND b.ACNT_STAT = '002' AND a.CODE = @ParamsText)
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './' + @UssdCode + ';bankcard::deactive-' + @ParamsText + '$del#' AS '@data',
                      @index AS '@order',
                      N'⭕ غیرفعال کردن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         ELSE 
         BEGIN
            -- Static
            SET @X = (
               SELECT './' + @UssdCode + ';bankcard::active-' + @ParamsText + '$del#' AS '@data',
                      @index AS '@order',
                      N'✅ فعال کردن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         
         -- Static
         SET @X = (
            SELECT '!./' + /* '*1*4*2*0#' */ @UssdCode + ';bankcard::edit-' + @ParamsText + '$del#' AS '@data',
                   @index AS '@order',
                   N'✏️ ویرایش' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT './' + @UssdCode + ';bankcard::reportin-' + @ParamsText + '$del#' AS '@data',
                   @index AS '@order',
                   N'📋 گزارش واریزی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT './' + @UssdCode + ';bankcard::showcards-$del#' AS '@data',
                   1 AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lesscashoutp' )
	   BEGIN
	      IF EXISTS(SELECT * FROM dbo.Robot r, dbo.Wallet w WHERE r.RBID = w.SRBT_ROBO_RBID AND w.CHAT_ID = @Chatid AND w.WLET_TYPE = '002' /* Cash Wallet */ AND ISNULL(r.MIN_WITH_DRAW, 0) > 0 AND (ISNULL(w.AMNT_DNRM, 0) - ISNULL(w.TEMP_AMNT_USE, 0)) >= ISNULL(r.MIN_WITH_DRAW, 0) )
	      BEGIN
	         -- Static
            SET @X = (
               SELECT './' + @UssdCode + ';wallet::depositshop-$del,lesswletdshp#' AS '@data',
                      @index AS '@order',
                      N'🏢 درخواست وجه از فروشگاه' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         IF EXISTS(SELECT * FROM dbo.Robot r, dbo.Wallet w WHERE r.RBID = w.SRBT_ROBO_RBID AND w.CHAT_ID = @Chatid AND w.WLET_TYPE IN ( '001', '002' ) /* Credit / Cash Wallet */ AND ISNULL(r.MIN_WITH_DRAW, 0) > 0 AND (ISNULL(w.AMNT_DNRM, 0) - ISNULL(w.TEMP_AMNT_USE, 0)) >= ISNULL(r.MIN_WITH_DRAW, 0) )
         BEGIN
            -- Static
            SET @X = (
               SELECT './' + @UssdCode + ';wallet::depositmembers-$del,lesswletdmbr#' AS '@data',
                      @index AS '@order',
                      N'👥 درخواست وجه از اعضا' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
            SET @index += 1;
         END 
         
         -- Static
         SET @X = (
            SELECT './' + @UssdCode + ';wallet::historydeposits-$del#' AS '@data',
                   @index AS '@order',
                   N'📋 لیست درخواستهای وجه' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lesswletdshp' )
	   BEGIN
	       -- Static
         SET @X = (
            SELECT './' + @UssdCode + ';wallet::depositshop::bankcard-$del,lesswletdshpacnt#' AS '@data',
                   @index AS '@order',
                   N'💳 انتخاب شماره حساب' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT '!./' + @UssdCode + ';wallet::depositshop::amount-$del,lesswletdshpamnt#' AS '@data',
                   @index AS '@order',
                   N'💵 مبلغ درخواست وجه' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
                  
         IF ISNULL(@OrdrCode, 0) != 0 AND NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.ORDR_CODE = @OrdrCode)
         BEGIN
            -- Dynamic
            SET @X = (
               SELECT './' + @UssdCode + ';wallet::depositshop::sendrequest-$del#' AS '@data',
                      @index AS '@order',
                      N'📩 ارسال درخواست وجه' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         ELSE IF ISNULL(@OrdrCode, 0) != 0
         BEGIN
            -- Dynamic
            SET @X = (
               SELECT './' + @UssdCode + ';wallet::depositshop::statusrequest-$del#' AS '@data',
                      @index AS '@order',
                      N'📩 وضعیت درخواست وجه' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         
         IF ISNULL(@OrdrCode, 0) != 0 AND NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.ORDR_CODE = @OrdrCode)
         BEGIN 
            -- Dynamic
            SET @X = (
               SELECT './' + @UssdCode + ';wallet::depositshop::cancelrequest-$del#' AS '@data',
                      @index AS '@order',
                      N'❌ انصراف درخواست وجه' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         -- Static
         SET @X = (
            SELECT './' + @UssdCode + ';wallet::deposit::homepage-$del#' AS '@data',
                   1 AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lesswletdshpacnt' )
	   BEGIN
	      -- بررسی اینکه آیا مشتری شماره کارت فعال دارد یا خیر
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Service_Robot sr, dbo.Service_Robot_Card_Bank a, dbo.Robot_Card_Bank_Account b
	          WHERE sr.SERV_FILE_NO = a.SRBT_SERV_FILE_NO
	            AND sr.ROBO_RBID = a.SRBT_ROBO_RBID
	            AND a.RCBA_CODE = b.CODE
	            AND b.ROBO_RBID = @Rbid
	            AND sr.CHAT_ID = @Chatid
	            AND b.ACNT_STAT = '002' -- فعال
	            AND b.ACNT_TYPE = '003' -- حساب های متفرقه مانند حساب مشتریان
	      )
	      BEGIN
	         SET @X = (
	            SELECT './' + @UssdCode + ';wallet::depositshop::bankcard::select-' + CAST(a.CODE AS VARCHAR(30)) + '$del,lesswletdshp#wallet::depositshop' AS '@data',
	                   ROW_NUMBER() OVER (ORDER BY b.CARD_NUMB) AS '@order',
	                   N'💳 ' + b.CARD_NUMB_DNRM + N' * ' + b.BANK_NAME  AS "text()"
	              FROM dbo.Service_Robot sr, dbo.Service_Robot_Card_Bank a, dbo.Robot_Card_Bank_Account b
	             WHERE sr.SERV_FILE_NO = a.SRBT_SERV_FILE_NO
	               AND sr.ROBO_RBID = a.SRBT_ROBO_RBID
	               AND a.RCBA_CODE = b.CODE
	               AND b.ROBO_RBID = @Rbid
	               AND sr.CHAT_ID = @Chatid
	               AND b.ACNT_STAT = '002' -- فعال
	               AND b.ACNT_TYPE = '003' -- حساب های متفرقه مانند حساب مشتریان
	             ORDER BY b.CARD_NUMB
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END 
	      ELSE
	      BEGIN 	      
	         -- Static
            SET @X = (
               SELECT '!./*1*4*2*0#;bankcard::new-024$#' AS '@data',
                      @index AS '@order',
                      N'💳 تعریف کارت جدید' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
         
         -- Static
         SET @X = (
            SELECT './' + @UssdCode + ';wallet::depositshop-$del,lesswletdshp#' AS '@data',
                   1 AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1; 
	   END 	   
	   ELSE IF @CmndText IN ( 'lesswletdshpamnt' )
	   BEGIN
	      -- بررسی اینکه آیا مشتری شماره کارت فعال دارد یا خیر
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Robot r, dbo.Service_Robot sr, dbo.Wallet w
	          WHERE r.RBID = sr.ROBO_RBID
	            AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
	            AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
	            AND sr.ROBO_RBID = @Rbid
	            AND sr.CHAT_ID = @Chatid
	            AND w.WLET_TYPE = '002' -- Cash Wallet
	            AND ISNULL(w.AMNT_DNRM, 0) - ISNULL(w.TEMP_AMNT_USE, 0) >= ISNULL(r.MIN_WITH_DRAW, 0)
	      )
	      BEGIN
	         SET @X = (
	            SELECT './' + @UssdCode + ';wallet::depositshop::amount::select-' + CAST((ISNULL(w.AMNT_DNRM, 0) - ISNULL(w.TEMP_AMNT_USE, 0)) AS VARCHAR(30)) + '$del,lesswletdshp#wallet::depositshop' AS '@data',
	                   ROW_NUMBER() OVER (ORDER BY w.CODE) AS '@order',
	                   N'💵 ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, (ISNULL(w.AMNT_DNRM, 0) - ISNULL(w.TEMP_AMNT_USE, 0))), 1), '.00', '')  AS "text()"
	              FROM dbo.Robot r, dbo.Service_Robot sr, dbo.Wallet w
	             WHERE r.RBID = sr.ROBO_RBID
	               AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
	               AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
	               AND sr.ROBO_RBID = @Rbid
	               AND sr.CHAT_ID = @Chatid
	               AND w.WLET_TYPE = '002' -- Cash Wallet
	               AND ISNULL(w.AMNT_DNRM, 0) - ISNULL(w.TEMP_AMNT_USE, 0) >= ISNULL(r.MIN_WITH_DRAW, 0)
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END 
         
         -- Static
         SET @X = (
            SELECT './' + @UssdCode + ';wallet::depositshop-$del,lesswletdshp#' AS '@data',
                   1 AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1; 
	   END 
	   ELSE IF @CmndText in ( 'notinewwithdrawtoacnt' )
	   BEGIN
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./*1*4*1#;wallet::withdrawshop::bankcard-{0}$del,lesswletwshpacnt#', @OrdrCode) AS '@data',
                   @index AS '@order',
                   N'💳 انتخاب کارت بانکی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./*1*4*1#;noaction-{0}$withdraw#<>', @OrdrCode) AS '@data',
                   @index AS '@order',
                   N'💳 کارت به کارت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('!./*1*4*1#;wallet::withdrawshop::rcptpay-{0}$lesswletwshprcpt#', @OrdrCode) AS '@data',
                   @index AS '@order',
                   N'💳 ارسال رسید پرداخت شبا' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lesswletwshpacnt' )
	   BEGIN
	      -- بررسی اینکه آیا مشتری شماره کارت فعال دارد یا خیر
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Service_Robot sr, dbo.Service_Robot_Card_Bank a, dbo.Robot_Card_Bank_Account b
	          WHERE sr.SERV_FILE_NO = a.SRBT_SERV_FILE_NO
	            AND sr.ROBO_RBID = a.SRBT_ROBO_RBID
	            AND a.RCBA_CODE = b.CODE
	            AND b.ROBO_RBID = @Rbid
	            AND sr.CHAT_ID = @Chatid
	            AND b.ORDR_TYPE = '024' -- حساب پرداخت پورسانت مشتریان
	            AND b.ACNT_STAT = '002' -- فعال
	            AND b.ACNT_TYPE = '002' -- حساب های فروشگاه
	      )
	      BEGIN
	         SET @X = (
	            SELECT './' + @UssdCode + ';wallet::withdrawshop::bankcard::select-' + CAST(@OrdrCode AS VARCHAR(30)) + ',' + CAST(a.CODE AS VARCHAR(30)) + '$del,notinewwithdrawtoacnt#' AS '@data',
	                   ROW_NUMBER() OVER (ORDER BY b.CARD_NUMB) AS '@order',
	                   N'💳 ' + b.CARD_NUMB_DNRM + N' * ' + b.BANK_NAME  AS "text()"
	              FROM dbo.Service_Robot sr, dbo.Service_Robot_Card_Bank a, dbo.Robot_Card_Bank_Account b
	             WHERE sr.SERV_FILE_NO = a.SRBT_SERV_FILE_NO
	               AND sr.ROBO_RBID = a.SRBT_ROBO_RBID
	               AND a.RCBA_CODE = b.CODE
	               AND b.ROBO_RBID = @Rbid
	               AND sr.CHAT_ID = @Chatid
	               AND b.ORDR_TYPE = '024' -- حساب پرداخت پورسانت مشتریان
	               AND b.ACNT_STAT = '002' -- فعال
	               AND b.ACNT_TYPE = '002' -- حساب های فروشگاه
	             ORDER BY b.CARD_NUMB
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END          
         -- Static
         SET @X = (
            SELECT './' + @UssdCode + dbo.STR_FRMT_U(';wallet::withdrawshop-{0}$del,notinewwithdrawtoacnt#', @OrdrCode) AS '@data',
                   1 AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1; 
	   END 
	   ELSE IF @CmndText IN ( 'lesswletwshprcpt' )
	   BEGIN
	      -- بررسی اینکه آیا ما رکوردی برای رسید پرداخت شبا مشتری داریم یا خیر
	      IF EXISTS(
	         SELECT *
	           FROM dbo.Order_State a
	          WHERE a.ORDR_CODE = @OrdrCode
	            AND a.AMNT_TYPE = '005'
	      )
	      BEGIN
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};wallet::withdrawshop::rcptpay::select-{1}$lesswletwshprcpt#', '*1*4#' + ',' + CAST(a.CODE AS varchar(30))) AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY a.STAT_DATE ) AS '@order',                      
                      CASE a.CONF_STAT WHEN '001' THEN N'⛔️ ' WHEN '002' THEN N'✅ ' WHEN '003' THEN N'⌛️ ' END + ISNULL(a.STAT_DESC, N'ارسال شده از واحد حسابداری') AS "text()"
                 FROM dbo.Order_State a
                WHERE a.ORDR_CODE = @OrdrCode
                  AND a.AMNT_TYPE = '005'
                  AND a.FILE_ID IS NOT NULL
                ORDER BY a.STAT_DATE
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
            SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
            
            -- Next Step #. Backup to UP MENU
	         -- Dynamic
	         SET @X = (
	            SELECT dbo.STR_FRMT_U('./{0};wallet::withdrawshop::rcptpay::confirm-{1}$del,notinewwithdrawtoacnt#' , '*1*4#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                   @index AS '@order',
	                   N'✅ تایید رسید واریز وجه' AS "text()"
	               FOR XML PATH('InlineKeyboardButton')
	         );
	         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END
	      
	      -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};wallet::withdrawshop-{1}$del,notinewwithdrawtoacnt#' , '*1*4#' + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessinforcptpay' )
	   BEGIN
	      SELECT @ConfStat = os.CONF_STAT,
	             @ConfDate = os.CONF_DATE,
	             @OrdrCode = os.ORDR_CODE
	        FROM dbo.Order_State os 
	       WHERE os.CODE = @OdstCode;
	       
	      IF @ConfStat = '003'
	      BEGIN
            -- Next Step #. حذف کردن رسید پرداخت
            -- Dynamic
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};wallet::withdrawshop::rcptpay::delete-{1}$del,lesswletwshprcpt#', @UssdCode + ',' + CAST(@OdstCode AS VARCHAR(30))) AS '@data',
                      @index AS '@order',
                      N'❌ حذف کردن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
         
         -- Next Step #. Backup to UP MENU
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};wallet::withdrawshop::rcptpay-{1}$del,lesswletwshprcpt#' , @UssdCode + ',' + CAST(@OrdrCode AS NVARCHAR(50))) AS '@data',
	                @index AS '@order',
	                N'⤴️ بازگشت' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	   END
	   ELSE IF @CmndText IN ('notiamazprodtocust') 
	   BEGIN
	      -- Next Step #. Edit Invoice
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$lessinfoprod#', @UssdCode + ',' + rp.TARF_CODE)  AS '@data',
                   ROW_NUMBER() OVER ( ORDER BY rp.TARF_CODE ) AS '@order',
                   N'📦 ' + rp.TARF_TEXT_DNRM AS "text()"	                        
              FROM dbo.Robot_Product rp, dbo.SplitString(@ParamsText, ',') P
             WHERE rp.ROBO_RBID = @Rbid
               AND rp.TARF_CODE = p.Item
             ORDER BY rp.TARF_CODE
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	   END 
	   ELSE IF @CmndText IN ('notinewprodstortocust') 
	   BEGIN
	      -- Next Step #. Edit Invoice
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$lessinfoprod#', @UssdCode + ',' + rp.TARF_CODE)  AS '@data',
                   ROW_NUMBER() OVER ( ORDER BY rp.TARF_CODE ) AS '@order',
                   N'📦 ' + rp.TARF_TEXT_DNRM AS "text()"	                        
              FROM dbo.Robot_Product rp, dbo.SplitString(@ParamsText, ',') P
             WHERE rp.ROBO_RBID = @Rbid
               AND rp.TARF_CODE = p.Item
             ORDER BY rp.TARF_CODE
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	   END 
	   ELSE IF @CmndText IN ('lesslockinvrwas')
	   BEGIN
	      -- Dynamic
         SET @X = (
            SELECT T.[@data], T.[@order], T.[text()]
              FROM (
               SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$lessinfoprod#', @UssdCode + ',' + a.ALTR_TARF_CODE_DNRM) AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY a.SIML_PRCT ) AS '@order',                      
                      N'(ک.ج): ' + p.TARF_TEXT_DNRM + CASE WHEN ISNULL(a.siml_prct, 0) != 0 THEN N' ' + CAST(a.siml_prct AS VARCHAR(10)) + N' %' ELSE N' ' END AS "text()"
                 FROM dbo.Robot_Product_Alternative a, dbo.Robot_Product p
                WHERE p.ROBO_RBID = @Rbid
                  AND p.TARF_CODE = @TarfCode
                  AND a.TARF_CODE_DNRM = p.TARF_CODE
                  AND a.STAT = '002'
                  AND p.CRNT_NUMB_DNRM > 0
                --ORDER BY a.SIML_PRCT
                  --FOR XML PATH('InlineKeyboardButton')
               UNION ALL
               SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$lessinfoprod#', @UssdCode + ',' + pt.TARF_CODE) AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY pt.TARF_CODE ) AS '@order',                      
                      N'(ک.م): ' + pt.TARF_TEXT_DNRM  AS "text()"
                 FROM dbo.Robot_Product ps, dbo.Robot_Product pt
                WHERE ps.ROBO_RBID = @Rbid
                  AND ps.ROBO_RBID = pt.ROBO_RBID
                  AND ps.TARF_CODE = @TarfCode
                  AND ps.GROP_JOIN_DNRM = pt.GROP_JOIN_DNRM
                  AND pt.STAT = '002'
                  AND pt.CRNT_NUMB_DNRM > 0
                  AND pt.TARF_CODE != @TarfCode
                --ORDER BY a.SIML_PRCT
             ) T
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
	   END 
	   ELSE IF @CmndText IN ('lessgiftprod')
	   BEGIN
	      -- Dynamic
         SET @X = (
            SELECT T.[@data], T.[@order], T.[text()]
              FROM (
               SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$lessinfoprod#', @UssdCode + ',' + rp.TARF_CODE) AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY rp.TARF_CODE ) AS '@order',                      
                      N'🎁 ' + rp.TARF_TEXT_DNRM AS "text()"
                 FROM dbo.Service_Robot_Seller_Product_Gift g, dbo.Service_Robot_Seller_Product p, dbo.Robot_Product rp
                WHERE g.TARF_CODE_DNRM = @TarfCode
                  AND g.SSPG_CODE = p.CODE
                  AND p.TARF_CODE = rp.TARF_CODE
                  AND rp.ROBO_RBID = @Rbid
                  AND g.STAT = '002'
                  AND p.CRNT_NUMB_DNRM > 0
                  AND rp.STAT = '002'
             ) T
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
	   END
	   ELSE IF @CmndText IN ('lesslinkprod')
	   BEGIN
	      -- Dynamic
         SET @X = (
            SELECT T.[@data], T.[@order], T.[text()]
              FROM (
               SELECT DISTINCT 
                      dbo.STR_FRMT_U('./{0};infoprod-{1}$lessinfoprod#', @UssdCode + ',' + rpt.TARF_CODE) AS '@data',
                      ROW_NUMBER() OVER ( ORDER BY rpt.TARF_CODE ) AS '@order',                      
                      N'🎁 ' + rpt.TARF_TEXT_DNRM AS "text()"
                 FROM dbo.Robot_Product rpt
                WHERE rpt.ROBO_RBID = @Rbid
                  AND rpt.TARF_CODE != @TarfCode
                  AND rpt.STAT = '002'
                  AND (
                        EXISTS (
                           SELECT *
                             FROM dbo.Robot_Product rps
                            WHERE rps.ROBO_RBID = rpt.ROBO_RBID
                              AND rps.TARF_CODE = @TarfCode
                              AND (
                                    rps.GROP_CODE_DNRM = rpt.GROP_CODE_DNRM OR 
                                    rps.BRND_CODE_DNRM = rpt.BRND_CODE_DNRM OR 
                                    rps.GROP_JOIN_DNRM = rpt.GROP_JOIN_DNRM
                                  )
                        ) OR 
                        EXISTS (
                           SELECT *
                             FROM dbo.Robot_Product_Alternative a
                            WHERE a.ALTR_RBPR_CODE = rpt.CODE
                              AND a.TARF_CODE_DNRM = @TarfCode
                              AND a.STAT = '002'
                        )                            
                     )
             ) T
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
	   END 
	   ELSE IF @CmndText IN ('lessfdbkprod')
	   BEGIN
	      DECLARE @NameNotVlid VARCHAR(3),
	              @ImagNotGood VARCHAR(3),
	              @InfoNotTrue VARCHAR(3),
	              @DescNotTrue VARCHAR(3),
	              @ProdNotOrgn VARCHAR(3),
	              @ProdHaveDupl VARCHAR(3);
	      SELECT @NameNotVlid = f.NAME_NOT_VLID,
	             @ImagNotGood = f.IMAG_NOT_GOOD,
	             @InfoNotTrue = f.INFO_NOT_TRUE,
	             @DescNotTrue = f.DESC_NOT_TRUE,
	             @ProdNotOrgn = f.PROD_NOT_ORGN,
	             @ProdHaveDupl = f.PROD_HAVE_DUPL	              
	        FROM dbo.Service_Robot_Product_Feedback f 
	       WHERE f.TARF_CODE_DNRM = @TarfCode AND f.CHAT_ID = @Chatid AND f.SRBT_ROBO_RBID = @Rbid;
	       
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};feedback:product-{1},001$del,lessfdbkprod#' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                CASE WHEN ISNULL(@NameNotVlid, '001') = '002' THEN N'☑️ ' ELSE N'🔲 ' END + N'نام کالا صحیح نیست' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};feedback:product-{1},002$del,lessfdbkprod#' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                CASE WHEN ISNULL(@ImagNotGood, '001') = '002' THEN N'☑️ ' ELSE N'🔲 ' END + N'عکس های کالا مناسب نیست' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};feedback:product-{1},003$del,lessfdbkprod#' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                CASE WHEN ISNULL(@InfoNotTrue, '001') = '002' THEN N'☑️ ' ELSE N'🔲 ' END + N'مشخصات فنی کالا صحیح نیست' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};feedback:product-{1},004$del,lessfdbkprod#' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                CASE WHEN ISNULL(@DescNotTrue, '001') = '002' THEN N'☑️ ' ELSE N'🔲 ' END + N'توضیحات کالا صحیح نیست' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};feedback:product-{1},005$del,lessfdbkprod#' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                CASE WHEN ISNULL(@ProdNotOrgn, '001') = '002' THEN N'☑️ ' ELSE N'🔲 ' END + N'این کالا غیراصل است' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};feedback:product-{1},006$del,lessfdbkprod#' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                CASE WHEN ISNULL(@ProdHaveDupl, '001') = '002' THEN N'☑️ ' ELSE N'🔲 ' END + N'کالا تکراری است' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Static
	      SET @X = (
	         SELECT dbo.STR_FRMT_U('./{0};feedback:product:rating-{1}$del,lessfdbkprod#' , @UssdCode + ',' + @TarfCode) AS '@data',
	                @index AS '@order',
	                N'⭐ امتیازی که به کالا میدین چیه؟' AS "text()"
	            FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	      SET @index += 1;
	      
	      -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$del,moreinfoprod#', @UssdCode + ',' + @TarfCode)  AS '@data',
                   @index AS '@order',
                   N'⤴️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ('lessrateprod')
	   BEGIN
	      -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./*0#;feedback:product:rate-{0},001$del,lessrateprod#', @TarfCode) AS '@data',
                   @index AS '@order',
                   N'⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./*0#;feedback:product:rate-{0},002$del,lessrateprod#', @TarfCode) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./*0#;feedback:product:rate-{0},003$del,lessrateprod#', @TarfCode) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./*0#;feedback:product:rate-{0},004$del,lessrateprod#', @TarfCode) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./*0#;feedback:product:rate-{0},005$del,lessrateprod#', @TarfCode) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};feedbackprod-{1}$del#', @UssdCode + ',' + @TarfCode)  AS '@data',
                   @index AS '@order',
                   N'⤴️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lessrecvmesg' )
	   BEGIN
	      -- پیام های جدید
	      IF EXISTS (SELECT * FROM dbo.Service_Robot_Replay_Message a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.VIST_STAT, '001') = '001' AND a.ORDT_ORDR_CODE IS NULL) OR
	         EXISTS (SELECT * FROM dbo.Service_Robot_Send_Advertising a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.VIST_STAT, '001') = '001')
	      BEGIN 
	         -- بدست آوردن تعداد پیام ها
	         SELECT @Numb = COUNT(a.RWNO)
	           FROM dbo.Service_Robot_Replay_Message a
	          WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.VIST_STAT, '001') = '001' AND a.ORDT_ORDR_CODE IS NULL;
	         
	         SELECT @Numb += COUNT(a.RWNO)
	           FROM dbo.Service_Robot_Send_Advertising a
	          WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.VIST_STAT, '001') = '001';
	         
	         -- Static
            SET @X = (
               SELECT './*1*11#;mailbox::inbox::new-$del#' AS '@data',
                      @index AS '@order',
                      N'🔵 پیام های جدید [ ' + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;            
         END 
         
         -- پیام های خوانده شده
         IF EXISTS (SELECT * FROM dbo.Service_Robot_Replay_Message a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.VIST_STAT, '001') = '002') OR
	         EXISTS (SELECT * FROM dbo.Service_Robot_Send_Advertising a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.VIST_STAT, '001') = '002')
	      BEGIN 
	         -- بدست آوردن تعداد پیام ها
	         SELECT @Numb = COUNT(a.RWNO)
	           FROM dbo.Service_Robot_Replay_Message a
	          WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.VIST_STAT, '001') = '002';
	         
	         SELECT @Numb += COUNT(a.RWNO)
	           FROM dbo.Service_Robot_Send_Advertising a
	          WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.VIST_STAT, '001') = '002';	         
	          
	         -- Static
            SET @X = (
               SELECT './*1*11#;mailbox::inbox::read-$del#' AS '@data',
                      @index AS '@order',
                      N'🟢 پیام های خواننده شده [ ' + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         
         -- پیام های تبلیغاتی
         IF EXISTS (SELECT * FROM dbo.Service_Robot_Send_Advertising a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid)
	      BEGIN 
	         -- تعداد پیام های تبلیغاتی
	         SELECT @Numb = COUNT(a.RWNO)
	           FROM dbo.Service_Robot_Send_Advertising a
	          WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid;
	          
	         -- Static
            SET @X = (
               SELECT './*1*11#;mailbox::inbox::adv-$del#' AS '@data',
                      @index AS '@order',
                      N'🟣 پیام های تبلیغاتی [ ' + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         
         -- پیام های فروشگاه
         IF EXISTS (SELECT * FROM dbo.Service_Robot_Replay_Message a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.WHO_SEND, '001') = '001')
	      BEGIN
	         -- تعداد پیام های فروشگاهی 
	         SELECT @Numb = COUNT(a.RWNO)
	           FROM dbo.Service_Robot_Replay_Message a 
	          WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND ISNULL(a.WHO_SEND, '001') = '001';
	          
	         -- Static
            SET @X = (
               SELECT './*1*11#;mailbox::inbox::shop-$del#' AS '@data',
                      @index AS '@order',
                      N'🟡 پیام های فروشگاه [ ' + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         
         -- پیام های معرف شما
         IF EXISTS (SELECT * FROM dbo.Service_Robot_Replay_Message a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND a.WHO_SEND = '002')
	      BEGIN 
	         -- تعداد پیام های معرف شما 
	         SELECT @Numb = COUNT(a.RWNO)
	           FROM dbo.Service_Robot_Replay_Message a 
	          WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND a.WHO_SEND = '002';
	          
	         -- Static
            SET @X = (
               SELECT './*1*11#;mailbox::inbox::overhead-$del#' AS '@data',
                      @index AS '@order',
                      N'🔴 پیام های معرف شما [ ' + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
         
         -- پیام های تیم پشتیبانی نرم افزار
         IF EXISTS (SELECT * FROM dbo.Service_Robot_Replay_Message a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND a.WHO_SEND = '003')
	      BEGIN 
	         -- تعداد پیام های معرف شما 
	         SELECT @Numb = COUNT(a.RWNO)
	           FROM dbo.Service_Robot_Replay_Message a 
	          WHERE a.SRBT_ROBO_RBID = @Rbid AND a.CHAT_ID = @Chatid AND a.WHO_SEND = '003';
	          
	         -- Static
            SET @X = (
               SELECT './*1*11#;mailbox::inbox::softwareteam-$del#' AS '@data',
                      @index AS '@order',
                      N'🟤 پیام های تیم پشتیبانی [ ' + + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END
	   END
	   -- ارسال پیام های کمپین تبلیغاتی
	   ELSE IF @CmndText IN ( 'lesssendmailadvcamp' )
	   BEGIN
	      -- پیام هایی آماده ارسال به کمپین تبلیغاتی         
         SELECT @Numb = COUNT(o.CODE)
           FROM dbo.[Order] o
          WHERE o.SRBT_ROBO_RBID = @Rbid
            AND o.ORDR_TYPE = '027'
            AND o.ORDR_STAT = '001';
            
         IF @Numb != 0
	      BEGIN
	         -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::readysendto::{1}-$del#', @UssdCode + ',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END) AS '@data',
                      @index AS '@order',
                      N'🟢 پیام های آماده ارسال [ ' + + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::delete::readysendto::{1}-$del#', @UssdCode + ',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END) AS '@data',
                      @index AS '@order',
                      N'❌ حذف پیام های آماده ارسال [ ' + + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END  
	      
         -- پیام هایی ارسال شده به کمپین تبلیغاتی
         SELECT @Numb = COUNT(o.CODE)
           FROM dbo.[Order] o
          WHERE o.SRBT_ROBO_RBID = @Rbid
            AND o.ORDR_TYPE = '027'
            AND o.ORDR_STAT = '004';
            
         IF @Numb != 0   	      
	      BEGIN	          
	         -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::sendedto::{1}-$del#', @UssdCode + ',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END) AS '@data',
                      @index AS '@order',
                      N'✅ پیام های ارسال شده [ ' + + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END
	   END 
	   ELSE IF @CmndText IN ( 'lesssendmailmngrshop', 'lesssendmailsoftteam', 'lesssendmailadvteam' ) 
	   BEGIN
         -- پیام هایی آماده ارسال به مدیر فروشگاه
         -- تعداد پیام های معرف شما 
         SELECT @Numb = COUNT(DISTINCT a.HEDR_CODE)
           FROM dbo.Service_Robot_Replay_Message a 
          WHERE a.SRBT_ROBO_RBID = @Rbid 
            AND a.HEDR_TYPE = CASE @UssdCode 
                                   WHEN '*1*11*1*0#' /* مدیر فروشگاه */ THEN '001' 
                                   WHEN '*1*11*1*1#' /* مدیر پشتیبانی نرم افزار فروشگاه */ THEN '003' 
                                   WHEN '*1*11*1*3#' /* مدیر تبلیغات فروشگاه */ THEN '006' 
                              END 
            AND a.CHAT_ID IN (
                SELECT sr.CHAT_ID
                 FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
                WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
                  AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
                  AND sr.ROBO_RBID = @Rbid
                  AND sg.GROP_GPID = CASE @CmndText
                                          WHEN 'lesssendmailmngrshop' THEN 131
                                          WHEN 'lesssendmailsoftteam' THEN 135
                                          WHEN 'lesssendmailadvteam' THEN 131
                                     END
                  AND sg.STAT = '002'
            )
            AND a.SNDR_CHAT_ID = @Chatid 
            AND a.SEND_STAT = '002';	      
         IF @Numb != 0
	      BEGIN
	         -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::readysendto::{1}-$del#', @UssdCode + ',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END) AS '@data',
                      @index AS '@order',
                      N'🟢 پیام های آماده ارسال [ ' + + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
            
            -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::delete::readysendto::{1}-$del#', @UssdCode + ',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END) AS '@data',
                      @index AS '@order',
                      N'❌ حذف پیام های آماده ارسال [ ' + + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END  
	      
         -- تعداد پیام های معرف شما 
         -- پیام هایی ارسال شده به مدیر فروشگاه
         SELECT @Numb = COUNT(DISTINCT a.HEDR_CODE)
           FROM dbo.Service_Robot_Replay_Message a 
          WHERE a.SRBT_ROBO_RBID = @Rbid 
            AND a.HEDR_TYPE = CASE @UssdCode 
                                   WHEN '*1*11*1*0#' /* مدیر فروشگاه */ THEN '001' 
                                   WHEN '*1*11*1*1#' /* مدیر پشتیبانی نرم افزار فروشگاه */ THEN '003' 
                                   WHEN '*1*11*1*3#' /* مدیر تبلیغات فروشگاه */ THEN '006' 
                               END 
            AND a.CHAT_ID IN (
                SELECT sr.CHAT_ID
                 FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
                WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
                  AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
                  AND sr.ROBO_RBID = @Rbid
                  AND sg.GROP_GPID = CASE @CmndText
                                          WHEN 'lesssendmailmngrshop' THEN 131
                                          WHEN 'lesssendmailsoftteam' THEN 135
                                          WHEN 'lesssendmailadvteam' THEN 131
                                     END
                  AND sg.STAT = '002'
            )
            AND a.SNDR_CHAT_ID = @Chatid 
            AND a.SEND_STAT IN ( '004', '005' /* گزینه آماده ارسال */ );
            
         IF @Numb != 0   	      
	      BEGIN	          
	         -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::sendedto::{1}-$del#', @UssdCode + ',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END) AS '@data',
                      @index AS '@order',
                      N'✅ پیام های ارسال شده [ ' + + CAST(@Numb AS NVARCHAR(10)) + N' ]' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END
	   END 
	   ELSE IF @CmndText IN ( 'lesssend1msgmngrshop', 'lesssend1msgsoftteam', 'lesssend1msgadvteam', 'lesssend1msgadvcamp' )
	   BEGIN
	      L$Send1Message:
	      IF @ParamsText IS NULL OR @ParamsText = ''
	      BEGIN
	         -- بدست آوردن کد مدیر فروشگاه
            SELECT TOP 1 
                   @TChatId = sr.CHAT_ID
              FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
             WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
               AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
               AND sr.ROBO_RBID = @Rbid
               AND sg.GROP_GPID = CASE @CmndText
                                       WHEN 'lesssend1msgmngrshop' THEN 131
                                       WHEN 'lesssend1msgsoftteam' THEN 135
                                       WHEN 'lesssend1msgadvteam' THEN 131
                                  END
               AND sg.STAT = '002';
            
            SELECT @TCode = a.HEDR_CODE
              FROM dbo.Service_Robot_Replay_Message a 
             WHERE a.SRBT_ROBO_RBID = @Rbid 
               AND a.SNDR_CHAT_ID = @ChatID 
               AND a.CHAT_ID = @TChatId 
               AND a.HEDR_TYPE = CASE @UssdCode 
                                      WHEN '*1*11*1*0#' /* مدیر فروشگاه */ THEN '001' 
                                      WHEN '*1*11*1*1#' /* مدیر پشتیبانی نرم افزار فروشگاه */ THEN '003' 
                                      WHEN '*1*11*1*3#' /* مدیر تبلیغات فروشگاه */ THEN '006' 
                                 END 
               AND a.SEND_STAT = '002';
         END 
         ELSE
            SET @TCode = @ParamsText;
            
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::sendto::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END + ',' + CAST(@TCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'📩 ارسال پیام' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::delete::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END + ',' + CAST(@TCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'❌ حذف پیام' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lesssendingmailmngrshop', 'lesssendingmailsoftteam', 'lesssendingmailadvteam' )
	   BEGIN
	      SET @X = (
	          SELECT TOP 10 dbo.STR_FRMT_U('./{0};mailbox::sendingbox::show::{1}-{2}$#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + ',' + CAST(a.HEDR_CODE AS VARCHAR(30))) AS '@data',
	                 ROW_NUMBER() OVER ( ORDER BY a.RPLY_DATE ) AS '@order',
	                 N'⏳ ' + SUBSTRING(dbo.GET_MTOS_U(a.RPLY_DATE), 3, 10) + N' - ' + CAST(CAST(a.RPLY_DATE AS TIME(0)) AS NVARCHAR(5)) + N' : ' + SUBSTRING(a.MESG_TEXT, 1, 30) + N' ...' AS "text()"
	            FROM (
	              SELECT DISTINCT a.HEDR_CODE, a.RPLY_DATE, a.MESG_TEXT
	               FROM dbo.Service_Robot_Replay_Message a
	              WHERE a.SRBT_ROBO_RBID = @Rbid 
	                AND a.HEDR_TYPE = CASE @UssdCode 
	                                       WHEN '*1*11*1*0#' /* مدیر فروشگاه */ THEN '001' 
	                                       WHEN '*1*11*1*1#' /* مدیر پشتیبانی نرم افزار فروشگاه */ THEN '003' 
	                                       WHEN '*1*11*1*3#' /* مدیر تبلیغات فروشگاه */ THEN '006' 
	                                  END 
                   AND a.CHAT_ID IN (
                       SELECT sr.CHAT_ID
                         FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
                        WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
                          AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
                          AND sr.ROBO_RBID = @Rbid
                          AND sg.GROP_GPID = CASE @UssdCode
                                                  WHEN '*1*11*1*0#' THEN 131
                                                  WHEN '*1*11*1*1#' THEN 135
                                                  WHEN '*1*11*1*3#' THEN 131
                                             END
                          AND sg.STAT = '002'
                   )
                   AND a.SNDR_CHAT_ID = @Chatid 
                   AND a.SEND_STAT = '002'
                ) a
                ORDER BY a.RPLY_DATE DESC 
                FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	      
	      -- گزینه ای برای نمایش تمامی پیام های آماده ارسال
	      IF (
	            SELECT COUNT(a.HEDR_CODE)
	               FROM (
	                 SELECT DISTINCT a.HEDR_CODE, a.RPLY_DATE, a.MESG_TEXT
	                  FROM dbo.Service_Robot_Replay_Message a
	                 WHERE a.SRBT_ROBO_RBID = @Rbid 
	                   AND a.HEDR_TYPE = CASE @UssdCode 
	                                          WHEN '*1*11*1*0#' /* مدیر فروشگاه */ THEN '001' 
	                                          WHEN '*1*11*1*1#' /* مدیر پشتیبانی نرم افزار فروشگاه */ THEN '003'
	                                          WHEN '*1*11*1*3#' /* مدیر تبلیغات فروشگاه */ THEN '006'
	                                     END 
                      AND a.CHAT_ID IN (
                          SELECT sr.CHAT_ID
                            FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
                           WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
                             AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
                             AND sr.ROBO_RBID = @Rbid
                             AND sg.GROP_GPID = CASE @UssdCode
                                                     WHEN '*1*11*1*0#' THEN 131
                                                     WHEN '*1*11*1*1#' THEN 135
                                                     WHEN '*1*11*1*3#' THEN 131
                                                END
                             AND sg.STAT = '002'
                      )
                      AND a.SNDR_CHAT_ID = @Chatid 
                      AND a.SEND_STAT = '002'
                   ) a
             ) > 10
	      BEGIN
	         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::showall::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END ) AS '@data',
                      @index AS '@order',
                      N'...' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @index += 1;
	      END 
	      
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lesssendingmailadvcamp' )
	   BEGIN
	      SET @X = (
	          SELECT TOP 10 dbo.STR_FRMT_U('./{0};mailbox::sendingbox::show::{1}-{2}$#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END + ',' + CAST(o.CODE AS VARCHAR(30))) AS '@data',
	                 ROW_NUMBER() OVER ( ORDER BY o.STRT_DATE ) AS '@order',
	                 N'⏳ ' + SUBSTRING(dbo.GET_MTOS_U(o.STRT_DATE), 3, 10) + N' - ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS NVARCHAR(5)) AS "text()"
	            FROM dbo.[Order] o
	           WHERE o.SRBT_ROBO_RBID = @Rbid
	             AND o.ORDR_TYPE = '027'
	             AND o.ORDR_STAT = '001'
                ORDER BY o.STRT_DATE DESC 
                FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	      
	      -- گزینه ای برای نمایش تمامی پیام های آماده ارسال
	      IF (
	            SELECT COUNT(o.CODE)
	               FROM dbo.[Order] o
	              WHERE o.SRBT_ROBO_RBID = @Rbid
	                AND o.ORDR_TYPE = '027'
	                AND o.ORDR_STAT = '001'
             ) > 10
	      BEGIN
	         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::showall::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END ) AS '@data',
                      @index AS '@order',
                      N'...' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @index += 1;
	      END 
	      
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lesssendedmailmngrshop', 'lesssendedmailsoftteam', 'lesssendedmailadvteam' )
	   BEGIN
	      SET @X = (
	          SELECT TOP 10 dbo.STR_FRMT_U('./{0};mailbox::sendedbox::show::{1}-{2}$#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + ',' + CAST(a.HEDR_CODE AS VARCHAR(30))) AS '@data',
	                 ROW_NUMBER() OVER ( ORDER BY a.RPLY_DATE ) AS '@order',
	                 CASE a.CONF_STAT WHEN '001' THEN N'⏳ ' WHEN '002' THEN N'✅ ' END + SUBSTRING(dbo.GET_MTOS_U(a.RPLY_DATE), 3, 10) + N' - ' + CAST(CAST(a.RPLY_DATE AS TIME(0)) AS NVARCHAR(5)) + N' : ' + SUBSTRING(a.MESG_TEXT, 1, 30) + N' ...' AS "text()"
	            FROM (
	             SELECT DISTINCT a.HEDR_CODE, a.RPLY_DATE, a.MESG_TEXT, a.CONF_STAT
	               FROM dbo.Service_Robot_Replay_Message a
	              WHERE a.SRBT_ROBO_RBID = @Rbid 
	                AND a.HEDR_TYPE = CASE @UssdCode 
	                                       WHEN '*1*11*1*0#' /* مدیر فروشگاه */ THEN '001' 
	                                       WHEN '*1*11*1*1#' /* مدیر پشتیبانی نرم افزار فروشگاه */ THEN '003' 
	                                       WHEN '*1*11*1*3#' /* مدیر تبلیغات فروشگاه */ THEN '006' 
	                                  END 
                   AND a.CHAT_ID IN (
                       SELECT sr.CHAT_ID
                         FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
                        WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
                          AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
                          AND sr.ROBO_RBID = @Rbid
                          AND sg.GROP_GPID = CASE @UssdCode
                                                  WHEN '*1*11*1*0#' THEN 131
                                                  WHEN '*1*11*1*1#' THEN 135
                                                  WHEN '*1*11*1*3#' THEN 131
                                             END
                          AND sg.STAT = '002'
                   )
                   AND a.SNDR_CHAT_ID = @Chatid 
                   AND a.SEND_STAT = '004'                
                ) a
                ORDER BY a.RPLY_DATE DESC 
                FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	      
	      -- گزینه ای برای نمایش تمامی پیام های ارسال شده
	      IF (
	            SELECT COUNT(a.HEDR_CODE)
	               FROM (
	                 SELECT DISTINCT a.HEDR_CODE, a.RPLY_DATE, a.MESG_TEXT
	                  FROM dbo.Service_Robot_Replay_Message a
	                 WHERE a.SRBT_ROBO_RBID = @Rbid 
	                   AND a.HEDR_TYPE = CASE @UssdCode 
	                                          WHEN '*1*11*1*0#' /* مدیر فروشگاه */ THEN '001' 
	                                          WHEN '*1*11*1*1#' /* مدیر پشتیبانی نرم افزار فروشگاه */ THEN '003' 
	                                          WHEN '*1*11*1*3#' /* مدیر تبلیغات فروشگاه */ THEN '006' 
	                                     END 
                      AND a.CHAT_ID IN (
                          SELECT sr.CHAT_ID
                            FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
                           WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
                             AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
                             AND sr.ROBO_RBID = @Rbid
                             AND sg.GROP_GPID = CASE @UssdCode
                                                     WHEN '*1*11*1*0#' THEN 131
                                                     WHEN '*1*11*1*1#' THEN 135
                                                     WHEN '*1*11*1*3#' THEN 131
                                                END
                             AND sg.STAT = '002'
                      )
                      AND a.SNDR_CHAT_ID = @Chatid 
                      AND a.SEND_STAT = '004'
                   ) a
             ) > 10
	      BEGIN
	         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::showall::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END ) AS '@data',
                      @index AS '@order',
                      N'...' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lesssendedmailadvcamp' )
	   BEGIN
	      SET @X = (
	          SELECT TOP 10 dbo.STR_FRMT_U('./{0};mailbox::sendedbox::show::{1}-{2}$#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END + ',' + CAST(o.CODE AS VARCHAR(30))) AS '@data',
	                 ROW_NUMBER() OVER ( ORDER BY o.STRT_DATE ) AS '@order',
	                 N'✅ ' + SUBSTRING(dbo.GET_MTOS_U(o.STRT_DATE), 3, 10) + N' - ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS NVARCHAR(5)) AS "text()"
	            FROM dbo.[Order] o
	           WHERE o.SRBT_ROBO_RBID = @Rbid
	             AND o.ORDR_TYPE = '027'
	             AND o.ORDR_STAT = '004'
                ORDER BY o.STRT_DATE DESC 
                FOR XML PATH('InlineKeyboardButton')
	      );
	      SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	      
	      -- گزینه ای برای نمایش تمامی پیام های ارسال شده
	      IF (
	            SELECT COUNT(o.CODE)
	               FROM dbo.[Order] o
	              WHERE o.SRBT_ROBO_RBID = @Rbid
	                AND o.ORDR_TYPE = '027'
	                AND o.ORDR_STAT = '004'
             ) > 10
	      BEGIN
	         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::showall::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END ) AS '@data',
                      @index AS '@order',
                      N'...' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
	         SET @index += 1;
	      END 
	      
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lesstrysendmngrshop', 'lesstrysendsoftteam', 'lesstrysendadvteam')
	   BEGIN
	      IF @CmndText = 'lesstrysendadvteam' AND EXISTS (SELECT * FROM dbo.Service_Robot_Replay_Message a WHERE a.SRBT_ROBO_RBID = @Rbid AND a.HEDR_CODE = @ParamsText AND a.HEDR_TYPE = '006' AND a.CONF_STAT = '002')
	      BEGIN
	         -- پیام هایی که تایید شده اند می توانیم درخواست ارسال پیام تبلیغاتی را اجرا کنیم
	         GOTO L$SenderAproveAdv;
	      END 
	      ELSE
	      BEGIN 
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::trysend::sendto::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + @ParamsText ) AS '@data',
                      @index AS '@order',
                      N'📩 ارسال مجدد' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
	   END 
	   ELSE IF @CmndText IN ('lessmenumailadvteam', 'moremenumailadvteam')
	   BEGIN
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::aprv::sendto::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + @ParamsText ) AS '@data',
                   @index AS '@order',
                   N'✅ تایید ارسال پیام' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::disaprv::sendto::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + @ParamsText ) AS '@data',
                   @index AS '@order',
                   N'⛔ عدم تایید ارسال پیام' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         IF @CmndText = 'moremenumailadvteam'
         BEGIN 
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::whois::sendto::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + @ParamsText ) AS '@data',
                      @index AS '@order',
                      N'👤 اطلاعات ارسال کننده پیام تبلیغات' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
         ELSE if @CmndText = 'lessmenumailadvteam'
         BEGIN
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::back::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END ) AS '@data',
                      @index AS '@order',
                      N'⬆️ بازگشت' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
         END 
	   END
	   ELSE IF @CmndText IN ('moremenumailadvcamp')
	   BEGIN
	      SET @X = (
            SELECT CASE 
                        WHEN od.ELMN_TYPE IN ('001') THEN 	                        
                            dbo.STR_FRMT_U('./{0};infoprod-{1}$lessinfoprod#', @UssdCode + ',' + od.TARF_CODE) 
                        WHEN od.ELMN_TYPE IN ('002', '003') THEN 
                           dbo.STR_FRMT_U('./{0};infoprod-{1},{2}$lessinfogfto#', @UssdCode + ',' + CAST(od.ORDR_CODE AS VARCHAR(30)) + ',' + CAST(od.RWNO AS VARCHAR(30))) 
                   END AS '@data',
                   ROW_NUMBER() OVER ( ORDER BY od.TARF_CODE ) AS '@order',
                   N'📣 ' + REPLACE(N'[ {0} ] ', N'{0}', od.TARF_CODE) + SUBSTRING(od.ORDR_DESC, 1, 30) + N' •••' AS "text()"	                        
              FROM dbo.Order_Detail od
             WHERE od.ORDR_CODE = @ParamsText
             ORDER BY od.TARF_CODE
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بستن' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lesssndraprvadv' ) 
	   BEGIN
	      L$SenderAproveAdv:
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::now::sendto::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + @ParamsText ) AS '@data',
                   @index AS '@order',
                   N'🟢 ارسال پیام به مخاطبین' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::anothertime::sendto::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + @ParamsText ) AS '@data',
                   @index AS '@order',
                   N'🟠 ارسال پیام در زمانی دیگر' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lesssndrdisaprvadv' )
	   BEGIN
	      GOTO L$Send1Message;
	   END 
	   ELSE IF @CmndText IN ('lessservadvmenu')
	   BEGIN
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::menuadv::like::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'👍 خوشم اومد' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::menuadv::dislike::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'👎 خوشم نیومد' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::menuadv::rate::{1}-{2},001$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::menuadv::rate::{1}-{2},002$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::menuadv::rate::{1}-{2},0003$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::menuadv::rate::{1}-{2},004$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendedbox::menuadv::rate::{1}-{2},005$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'⭐️⭐️⭐️⭐️⭐️ ' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;         
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بستن' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lessordradvcamp' )
	   BEGIN
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::sendto::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'✅ تایید درخواست کمپین تبلیغاتی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::delete::{1}-{2}$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END + N',' + CAST(@OrdrCode AS NVARCHAR(30))) AS '@data',
                   @index AS '@order',
                   N'❌ انصراف درخواست کمپین تبلیغاتی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back::{1}-$del#', @UssdCode + N',' + CASE @UssdCode WHEN '*1*11*1*0#' THEN 'mngrshop' WHEN '*1*11*1*1#' THEN 'softteam' WHEN '*1*11*1*3#' THEN 'advteam' WHEN '*1*11*1*4#' THEN 'advcamp' END ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lessshowmesg' )
	   BEGIN
	      SET @X = (
             SELECT TOP 7
                    T.DATA AS '@data',
                    ROW_NUMBER() OVER ( ORDER BY T.SEND_DATE ) AS '@order',                      
                    N'✉️ ' + T.WHO_SEND_DESC + N' ' + dbo.GET_MTOS_U(T.SEND_DATE) + N' - ' + CAST(CAST(T.SEND_DATE AS TIME(0)) AS VARCHAR(5)) AS "text()"
               FROM (
                  SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::rplymesg-{1}$#', @UssdCode + ',' + CAST(a.RWNO AS VARCHAR(30))) AS DATA,
                         w.DOMN_DESC AS WHO_SEND_DESC, a.MESG_TEXT AS SEND_MESG, a.RPLY_DATE AS SEND_DATE
                    FROM dbo.Service_Robot_Replay_Message a LEFT OUTER JOIN dbo.[D$WHOS] w ON ISNULL(a.WHO_SEND, '001') = w.VALU
                   WHERE a.SRBT_ROBO_RBID = @Rbid
                     AND a.CHAT_ID = @ChatID
                     AND ISNULL(a.VIST_STAT, '001') = CASE @ParamsText WHEN '000' THEN ISNULL(a.VIST_STAT, '001') ELSE @ParamsText END 
                     AND a.ORDT_ORDR_CODE IS NULL
                  UNION ALL 
                  SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::{1}-{2}$#', @UssdCode + ',' + CASE o.ORDR_TYPE WHEN '026' THEN 'advteam' WHEN '027' THEN 'advcamp' END + N',' + CAST(sa.RWNO AS VARCHAR(30))) AS DATA,
                         ot.DOMN_DESC AS WHO_SEND_DESC, a.TEXT_MESG AS SEND_MESG, o.STRT_DATE AS SEND_DATE
                    FROM dbo.Service_Robot_Send_Advertising sa, dbo.Send_Advertising a, dbo.[Order] o, dbo.[D$ORDT] ot
                   WHERE sa.SRBT_ROBO_RBID = @Rbid
                     AND sa.CHAT_ID = @ChatID
                     AND ISNULL(sa.VIST_STAT, '001') = CASE @ParamsText WHEN '000' THEN ISNULL(sa.VIST_STAT, '001') ELSE @ParamsText END 
                     AND sa.SDAD_ID = a.ID
                     AND a.ORDR_CODE = o.CODE
                     AND o.ORDR_TYPE = ot.VALU
                     AND o.ORDR_TYPE IN ( '026', '027' )
               ) T
              ORDER BY T.SEND_DATE DESC 
                FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
         
         IF (
            SELECT COUNT(*)
               FROM (
                  SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::rplymesg-{1}$#', @UssdCode + ',' + CAST(a.RWNO AS VARCHAR(30))) AS DATA,
                         w.DOMN_DESC AS WHO_SEND_DESC, a.MESG_TEXT AS SEND_MESG, a.RPLY_DATE AS SEND_DATE
                    FROM dbo.Service_Robot_Replay_Message a LEFT OUTER JOIN dbo.[D$WHOS] w ON ISNULL(a.WHO_SEND, '001') = w.VALU
                   WHERE a.SRBT_ROBO_RBID = @Rbid
                     AND a.CHAT_ID = @ChatID
                     AND ISNULL(a.VIST_STAT, '001') = @ParamsText
                     AND a.ORDT_ORDR_CODE IS NULL
                  UNION ALL 
                  SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::advcamp-{1}$#', @UssdCode + ',' + CAST(sa.RWNO AS VARCHAR(30))) AS DATA,
                         ot.DOMN_DESC AS WHO_SEND_DESC, a.TEXT_MESG AS SEND_MESG, o.STRT_DATE AS SEND_DATE
                    FROM dbo.Service_Robot_Send_Advertising sa, dbo.Send_Advertising a, dbo.[Order] o, dbo.[D$ORDT] ot
                   WHERE sa.SRBT_ROBO_RBID = @Rbid
                     AND sa.CHAT_ID = @ChatID
                     AND ISNULL(sa.VIST_STAT, '001') = @ParamsText
                     AND sa.SDAD_ID = a.ID
                     AND a.ORDR_CODE = o.CODE
                     AND o.ORDR_TYPE = ot.VALU
                     AND o.ORDR_TYPE = '027'
               ) T
         ) > 7
         BEGIN
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::showall-$del#', @UssdCode ) AS '@data',
                      @index AS '@order',
                      N'...' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @index += 1;
         END 
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessshowadvmesg' )
	   BEGIN
	      SET @X = (
             SELECT TOP 7
                    T.DATA AS '@data',
                    ROW_NUMBER() OVER ( ORDER BY T.SEND_DATE ) AS '@order',                      
                    N'✉️ ' + T.WHO_SEND_DESC + N' ' + dbo.GET_MTOS_U(T.SEND_DATE) + N' - ' + CAST(CAST(T.SEND_DATE AS TIME(0)) AS VARCHAR(5)) AS "text()"
               FROM (
                  SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::{1}-{2}$#', @UssdCode + ',' + CASE o.ORDR_TYPE WHEN '026' THEN 'advteam' WHEN '027' THEN 'advcamp' END + N',' + CAST(sa.RWNO AS VARCHAR(30))) AS DATA,
                         ot.DOMN_DESC AS WHO_SEND_DESC, a.TEXT_MESG AS SEND_MESG, o.STRT_DATE AS SEND_DATE
                    FROM dbo.Service_Robot_Send_Advertising sa, dbo.Send_Advertising a, dbo.[Order] o, dbo.[D$ORDT] ot
                   WHERE sa.SRBT_ROBO_RBID = @Rbid
                     AND sa.CHAT_ID = @ChatID                     
                     AND sa.SDAD_ID = a.ID
                     AND a.ORDR_CODE = o.CODE
                     AND o.ORDR_TYPE = ot.VALU
                     AND o.ORDR_TYPE IN ( '026', '027' )
               ) T
              ORDER BY T.SEND_DATE DESC 
                FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
         
         IF (
            SELECT COUNT(*)
               FROM (                  
                  SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::advcamp-{1}$#', @UssdCode + ',' + CAST(sa.RWNO AS VARCHAR(30))) AS DATA,
                         ot.DOMN_DESC AS WHO_SEND_DESC, a.TEXT_MESG AS SEND_MESG, o.STRT_DATE AS SEND_DATE
                    FROM dbo.Service_Robot_Send_Advertising sa, dbo.Send_Advertising a, dbo.[Order] o, dbo.[D$ORDT] ot
                   WHERE sa.SRBT_ROBO_RBID = @Rbid
                     AND sa.CHAT_ID = @ChatID
                     AND sa.SDAD_ID = a.ID
                     AND a.ORDR_CODE = o.CODE
                     AND o.ORDR_TYPE = ot.VALU
                     AND o.ORDR_TYPE = '027'
               ) T
         ) > 7
         BEGIN
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::showall-$del#', @UssdCode ) AS '@data',
                      @index AS '@order',
                      N'...' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @index += 1;
         END 
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lessshowwhosmesg' )
	   BEGIN
	      SET @X = (
             SELECT TOP 7
                    T.DATA AS '@data',
                    ROW_NUMBER() OVER ( ORDER BY T.SEND_DATE ) AS '@order',                      
                    N'✉️ ' + T.WHO_SEND_DESC + N' ' + dbo.GET_MTOS_U(T.SEND_DATE) + N' - ' + CAST(CAST(T.SEND_DATE AS TIME(0)) AS VARCHAR(5)) AS "text()"
               FROM (
                  SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::rplymesg-{1}$#', @UssdCode + ',' + CAST(a.RWNO AS VARCHAR(30))) AS DATA,
                         w.DOMN_DESC AS WHO_SEND_DESC, a.MESG_TEXT AS SEND_MESG, a.RPLY_DATE AS SEND_DATE
                    FROM dbo.Service_Robot_Replay_Message a LEFT OUTER JOIN dbo.[D$WHOS] w ON ISNULL(a.WHO_SEND, '001') = w.VALU
                   WHERE a.SRBT_ROBO_RBID = @Rbid
                     AND a.CHAT_ID = @ChatID
                     AND ISNULL(a.WHO_SEND, '001') = @ParamsText
               ) T
              ORDER BY T.SEND_DATE DESC 
                FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
         SET @Index = @X.value('count(//InlineKeyboardButton)', 'INT') + 1;
         
         IF (
            SELECT COUNT(*)
               FROM (
                  SELECT dbo.STR_FRMT_U('./{0};mailbox::inbox::show::rplymesg-{1}$#', @UssdCode + ',' + CAST(a.RWNO AS VARCHAR(30))) AS DATA,
                         w.DOMN_DESC AS WHO_SEND_DESC, a.MESG_TEXT AS SEND_MESG, a.RPLY_DATE AS SEND_DATE
                    FROM dbo.Service_Robot_Replay_Message a LEFT OUTER JOIN dbo.[D$WHOS] w ON ISNULL(a.WHO_SEND, '001') = w.VALU
                   WHERE a.SRBT_ROBO_RBID = @Rbid
                     AND a.CHAT_ID = @ChatID
                     AND ISNULL(a.WHO_SEND, '001') = @ParamsText                     
               ) T
         ) > 7
         BEGIN
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};mailbox::sendingbox::showall-$del#', @UssdCode ) AS '@data',
                      @index AS '@order',
                      N'...' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');
	         SET @index += 1;
         END 
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};mailbox::back-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lessnewrecpordr' )
	   BEGIN
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};receptionorder::show::crnt::cart::items-{1}$#', '*0#' + ',' + CAST(@OrdrCode AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'📝 نمایش اقلام سفارش شما' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
	      SET @X = (
            SELECT --dbo.STR_FRMT_U('./{0};receptionorder::ok-{1}$del#', @UssdCode + ',' + CAST(@OrdrCode AS VARCHAR(30)) ) AS '@data',
                   dbo.STR_FRMT_U('@/FRST_PAGE_F;receptionorder::ok-{1}$#', @UssdCode + ',' + CAST(@OrdrCode AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'✅ تایید سفارش' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};receptionorder::cancel-{1}$del#', @UssdCode + ',' + CAST(@OrdrCode AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'❌ انصراف سفارش' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lesswaitrecpordr', 'lessworkrecpordr', 'lessendrecpordr' )
	   BEGIN
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};receptionorder::show::working::cart::items-{1}$#', '*0#' + ',' + CAST(@OrdrCode AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'📝 نمایش اقلام سفارش شما' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};receptionorder::refresh-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⬆️ بازگشت' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 
	   ELSE IF @CmndText IN ( 'lesshistrecpordr' )
	   BEGIN
	      -- ابتدا بررسی میکنیم که درخواست موقتی وجود دارد یا خیر
	      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.SRBT_ROBO_RBID = @Rbid AND o.CHAT_ID = @Chatid AND o.ORDR_TYPE = '025' AND o.ORDR_STAT = '001')
	      BEGIN
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};receptionorder::show::crnt::cart-{1}$del#', @UssdCode + ',' + CAST(o.CODE AS VARCHAR(30)) ) AS '@data',
                      @index AS '@order',
                      N'📝 سفارش فعلی شما' AS "text()"
                 FROM dbo.[Order] o
                WHERE o.SRBT_ROBO_RBID = @Rbid 
                  AND o.CHAT_ID = @Chatid 
                  AND o.ORDR_TYPE = '025' 
                  AND o.ORDR_STAT = '001'
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @index += 1;
	      END 
	      
	      -- گزینه بعدی اینکه بررسی میکنیم که چه درخواست هایی وجود دارد که ارسال شده اند ولی هنوز قسمت پذیرش تاییدی برای انجام نداده اند 
	      IF EXISTS(SELECT * FROM dbo.[Order] o25 WHERE o25.SRBT_ROBO_RBID = @Rbid AND o25.CHAT_ID = @Chatid AND o25.ORDR_TYPE = '025' AND o25.ORDR_STAT IN ( '002' ) /*AND NOT EXISTS (SELECT * FROM dbo.[Order] o4 WHERE o25.CODE = o4.ORDR_CODE)*/)
	      BEGIN
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};receptionorder::show::waiting::cart-{1}$del#', @UssdCode + ',' + CAST(o25.CODE AS VARCHAR(30)) ) AS '@data',
                      ROW_NUMBER() OVER (ORDER BY o25.CODE) AS '@order',
                      N'📝 سفارش ارسال شده' AS "text()"
                 FROM dbo.[Order] o25
                WHERE o25.SRBT_ROBO_RBID = @Rbid 
                  AND o25.CHAT_ID = @Chatid 
                  AND o25.ORDR_TYPE = '025' 
                  AND o25.ORDR_STAT IN ( '002' )
                  --AND NOT EXISTS (SELECT * FROM dbo.[Order] o4 WHERE o25.CODE = o4.ORDR_CODE)
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END 
	      
	      -- گزینه بعدی اینکه بررسی میکنیم که چه درخواست هایی وجود دارد که ارسال شده اند و قسمت پذیرش تاییدیه برای انجام داده اند
	      IF EXISTS(SELECT * FROM dbo.[Order] o25 WHERE o25.SRBT_ROBO_RBID = @Rbid AND o25.CHAT_ID = @Chatid AND o25.ORDR_TYPE = '025' AND o25.ORDR_STAT IN ( '016' ) /*AND NOT EXISTS (SELECT * FROM dbo.[Order] o4 WHERE o25.CODE = o4.ORDR_CODE)*/)
	      BEGIN
	         SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};receptionorder::show::working::cart-{1}$del#', @UssdCode + ',' + CAST(o25.CODE AS VARCHAR(30)) ) AS '@data',
                      ROW_NUMBER() OVER (ORDER BY o25.CODE) AS '@order',
                      N'🛒 سفارش در حال انجام' AS "text()"
                 FROM dbo.[Order] o25
                WHERE o25.SRBT_ROBO_RBID = @Rbid 
                  AND o25.CHAT_ID = @Chatid 
                  AND o25.ORDR_TYPE = '025' 
                  AND o25.ORDR_STAT IN ( '016' )
                  --AND NOT EXISTS (SELECT * FROM dbo.[Order] o4 WHERE o25.CODE = o4.ORDR_CODE)
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END 
	      
	      -- و در آخر چه درخواست هایی ثبت شده اند و پایانی شده اند
	      IF EXISTS(SELECT * FROM dbo.[Order] o25 WHERE o25.SRBT_ROBO_RBID = @Rbid AND o25.CHAT_ID = @Chatid AND o25.ORDR_TYPE = '025' AND o25.ORDR_STAT = '004' AND EXISTS (SELECT * FROM dbo.[Order] o4 WHERE o25.CODE = o4.ORDR_CODE AND EXISTS (SELECT * FROM dbo.Order_Step_History h WHERE o4.CODE = h.ORDR_CODE AND h.ORDR_STAT = '004')))
	      BEGIN
	         SET @X = (
               SELECT TOP 3 
                      dbo.STR_FRMT_U('./{0};receptionorder::show::ended::cart-{1}$del#', @UssdCode + ',' + CAST(o25.CODE AS VARCHAR(30)) ) AS '@data',
                      ROW_NUMBER() OVER (ORDER BY o25.CODE) AS '@order',
                      N'✅ فاکتور ' + CAST(o25.ORDR_TYPE_NUMB AS VARCHAR(10)) AS "text()"
                 FROM dbo.[Order] o25
                WHERE o25.SRBT_ROBO_RBID = @Rbid 
                  AND o25.CHAT_ID = @Chatid 
                  AND o25.ORDR_TYPE = '025' 
                  AND o25.ORDR_STAT = '004'
                  AND EXISTS (SELECT * FROM dbo.[Order] o4 WHERE o25.CODE = o4.ORDR_CODE AND EXISTS (SELECT * FROM dbo.Order_Step_History h WHERE o4.CODE = h.ORDR_CODE AND h.ORDR_STAT = '004'))
                  ORDER BY o25.CRET_DATE DESC
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
            SET @Index = @XRet.value('count(//InlineKeyboardButton)', 'INT') + 1;
	      END
	      
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};receptionorder::refresh-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'🔄 بروزرسانی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1; 
	   END 
	   ELSE IF @CmndText IN ( 'lessconfrcpt' )
	   BEGIN
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};acntman::ordrrcpt::show::newrcpt-{1}$moreconfrcpt#', @UssdCode + ',' + CAST(os.CODE AS VARCHAR(30)) ) AS '@data',
                   ROW_NUMBER() OVER ( ORDER BY os.CODE ) AS '@order',
                   N'⏳  سند پرداخت ' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(10)) + N' - ' + o.OWNR_NAME AS "text()"
               FROM dbo.[Order] o, dbo.Order_State os
              WHERE o.CODE = os.ORDR_CODE
                AND o.ORDR_STAT = '001'
                AND os.CONF_STAT = '003'
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Next Step #. More Menu
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⛔ بستن' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ('moreconfrcpt') 
	   BEGIN
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};acntman::ordrrcpt::aprov::newrcpt-{1}$#', '*0#' + ',' + CAST(@OdstCode AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'✅ تایید رسید به صورت کامل' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};acntman::ordrrcpt::manual::newrcpt-{1}$del#', '*0#' + ',' + CAST(@OdstCode AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'🖐️ نیاز به تایید دستی' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};acntman::ordrrcpt::notaprov::newrcpt-{1}$del#', '*0#' + ',' + CAST(@OdstCode AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'🚫 عدم تایید رسید' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         -- Next Step #. More Menu
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⛔ بستن' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END
	   ELSE IF @CmndText IN ( 'lessconfsupl' ) 
	   BEGIN
	      SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};humnreso::rqstsupl::aprov-{1}$del#', '*0#' + ',' + CAST(@Chatid AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'✅ تایید درخواست همکاری' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};humnreso::rqstsupl::notaprov-{1}$del#', '*0#' + ',' + CAST(@Chatid AS VARCHAR(30)) ) AS '@data',
                   @index AS '@order',
                   N'🚫 عدم تایید درخواست همکاری' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
         
	      -- Next Step #. More Menu
         -- Static
         SET @X = (
            SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                   @index AS '@order',
                   N'⛔ بستن' AS "text()"
               FOR XML PATH('InlineKeyboardButton')
         );
         SET @XRet.modify('insert sql:variable("@X") as last into (.)[1]');	      
         SET @index += 1;
	   END 	   
	L$EndSP:   
	COMMIT TRAN [T$DYN_ILQM_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$DYN_ILQM_P];
	END CATCH	
END
GO
