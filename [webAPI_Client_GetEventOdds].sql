USE [DB_A2CB54_11]
GO
/****** Object:  StoredProcedure [dbo].[webAPI_Client_GetEventOdds]    Script Date: 12/8/2017 9:19:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[webAPI_Client_GetEventOdds]
	@EventIds VARCHAR(MAX),
	@LanguageCode CHAR(2),
	@BetTypeGroupIds VARCHAR(MAX),
	@BettingLineTemplateID INT,
	@Type INT
AS
BEGIN
	--DECLARE 
		--@EventIds VARCHAR(MAX) = '1|3|5|10',
		--@LanguageCode CHAR(2) = 'EN',
		--@BetTypeGroupIds VARCHAR(MAX) = NULL,
		--@BettingLineTemplateID INT = 1,
		--@Type INT = 0

	SET NOCOUNT ON;

	IF @BettingLineTemplateID IS NULL
		SET @BettingLineTemplateID = 1

	IF @LanguageCode IS NULL
		SELECT TOP 1 @LanguageCode = [DefLanguageCode] FROM dbo.[SystemSettings] WITH(NOLOCK)
	
	DECLARE @Sports as Table
	( SportID int )
	
	INSERT INTO @Sports ([SportId])
	SELECT DISTINCT L.[SportId]
	FROM dbo.[Event] E WITH(NOLOCK)
		INNER JOIN dbo.[League] L WITH(NOLOCK) ON E.LeagueID = L.ID
	WHERE E.[Id] IN (SELECT [id_value] FROM dbo.[ConvertToTable](@EventIds, '|'))
		AND (@BettingLineTemplateID = 1 OR E.[ID] IN (SELECT [EventID] FROM dbo.[BettingLineTemplateEvents] BLTE WITH(NOLOCK) WHERE BLTE.[BettingLineTemplateID] = @BettingLineTemplateID))

		
	SELECT EO.[Id], EO.[EventId], EO.[BetTypeId], EO.[OddTypeId], BTGBT.[BetTypeGroupId] as [BetGroupId], EO.[OddPoint], EO.[TeamId], ISNULL(EO.[OddFactor], 1) AS [OddFactor],
		CAST(0 AS SMALLINT) AS [ColumnNumber], BTG.[SportId]
	FROM  dbo.[BetTypeGroup] AS BTG WITH(NOLOCK) 
		INNER JOIN dbo.[BetTypeGroupBetType] AS BTGBT WITH(NOLOCK) ON BTGBT.[BetTypeGroupId] = BTG.[Id]
		INNER JOIN dbo.[BetType] AS BT WITH(NOLOCK) ON BTGBT.[BetTypeId] = BT.[Id]
		CROSS JOIN (SELECT [id_value] FROM dbo.[ConvertToTable](@EventIds, '|')) CTT
		INNER JOIN dbo.[EventOdds] AS EO WITH(NOLOCK) ON CTT.[id_value] = EO.[EventId] AND BT.[Id] = EO.[BetTypeId]
	WHERE BTG.[SportId] IN (SELECT [SportID] FROM @Sports) 
		AND BTG.[BetTypeGroupTemplateId] = 1
		AND EO.[Status] = 0 AND EO.[BettingLineTemplateID] = @BettingLineTemplateID
		AND (@Type = 0 OR EO.[BetTypeId] IN (SELECT BSBT.[BetTypeId] FROM dbo.[BaseSportBetTypes] AS BSBT WHERE BTG.[SportId] = BSBT.[SportId]))
		AND (@BetTypeGroupIds IS NULL OR BTGBT.[BetTypeGroupId] IN (SELECT [id_value] FROM dbo.[ConvertToTable](@BetTypeGroupIds, '|')))
	OPTION(FORCE ORDER)
END
