USE [DB_A2CB54_11]
GO
/****** Object:  StoredProcedure [dbo].[webAPI_Client_GetSportsTree]    Script Date: 12/8/2017 9:18:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[webAPI_Client_GetSportsTree]
	@LanguageCode char(2) = 'EN',
	@Duration INT = NULL,
	@BettingLineTemplateID int = 1,
	@Day datetime = null,
	@Bias int = NULL,
	@BetTypeGroupTemplateId INT = 1
AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE
	--	@LanguageCode char(2) = 'EN',
	--	@Duration INT = NULL,
	--	@BettingLineTemplateID int = 1,
	--	@Day datetime = null,
	--	@Bias int = NULL,
	--	@BetTypeGroupTemplateId INT = 1

    IF @BettingLineTemplateID IS NULL
		SET @BettingLineTemplateID = 1

	IF @BetTypeGroupTemplateId IS NULL
		SET @BetTypeGroupTemplateId = 1
 
	IF @Bias IS NULL
		SET @Bias = 0

	IF @Day IS NOT NULL
	BEGIN
		SET @Day = CAST(CAST(@Day AS DATE) AS DATETIME)
		IF CAST(CAST(DATEADD(MINUTE, @Bias , GETUTCDATE()) AS DATE) AS DATETIME) <> @Day
			SET @Duration = NULL
	END
  
	DECLARE @TimeOut INT
	IF @LanguageCode IS NULL
		SELECT TOP 1 @LanguageCode = [DefLanguageCode], @TimeOut = [EventTimeout] FROM dbo.[SystemSettings] WITH(NOLOCK)
	ELSE 
		SELECT TOP 1 @TimeOut = [EventTimeout] FROM dbo.[SystemSettings] WITH(NOLOCK)

	DECLARE @Events AS TABLE ([LeagueId] INT, [EventCount] INT, [BetTypeGroupId] INT, [BetTypeGroupName] NVARCHAR(50), [BetTypeGroupOrdering] INT)
 
	INSERT INTO @Events ([LeagueId], [EventCount], [BetTypeGroupId], [BetTypeGroupName], [BetTypeGroupOrdering])
	SELECT E.[LeagueID], COUNT(E.ID), EO.[BetTypeGroupId], EO.[BetTypeGroupName], EO.[Ordering]
	FROM dbo.[Event] E WITH(NOLOCK)
	CROSS APPLY
	(
		SELECT [EventId], BTG.[Id] AS [BetTypeGroupId], BTG.[Name] AS [BetTypeGroupName], BTG.[Ordering]
		FROM dbo.[EventOdds] EO WITH(NOLOCK)
			INNER JOIN dbo.[BetTypeGroupBetType] BTGBT WITH(NOLOCK) ON BTGBT.[BetTypeId] = EO.BetTypeId
			INNER JOIN dbo.[BetTypeGroup] BTG WITH(NOLOCK) ON BTG.[BetTypeGroupTemplateId] = @BetTypeGroupTemplateId AND BTGBT.[BetTypeGroupId] = BTG.[Id]
		WHERE EO.[BettingLineTemplateId] = @BettingLineTemplateID AND BTG.[SportId] = E.[SportId]
			AND E.ID = EO.EventID AND EO.[Status] = 0 AND EO.[OddFactor] > 1
		GROUP BY [EventId], BTG.[Id], BTG.[Name], BTG.[Ordering]
	) AS EO
	WHERE E.EventDate BETWEEN DATEADD(mi, 1 * @TimeOut, GETUTCDATE()) 
		AND CASE WHEN @Duration IS NULL THEN DATEADD(dd, 366, GETUTCDATE()) ELSE DATEADD(MINUTE, @Duration, GETUTCDATE()) END
		AND (@Day IS NULL OR (E.[EventDate] < DATEADD(MINUTE, @Bias * -1, DATEADD(DAY,1,@Day))
		AND E.[EventDate] > DATEADD(MINUTE, @Bias * -1, @Day)))
		AND E.[EventDate] > DATEADD(MINUTE, @TimeOut, GETUTCDATE())
		AND E.[Status] = 0
		AND E.[LeagueStatus] = 1
		AND (@BettingLineTemplateID = 1 OR E.[ID] IN (SELECT [EventID] FROM dbo.[BettingLineTemplateEvents] BLTE WITH(NOLOCK) WHERE BLTE.[BettingLineTemplateID] = @BettingLineTemplateID ))
	GROUP BY E.[LeagueID], [BetTypeGroupId], [BetTypeGroupName], EO.[Ordering]
	OPTION (FORCE ORDER)

	SELECT L.[Id] AS [LeagueId], SUBSTRING(L.[Name], 0, 50) AS [LeagueName],
		C.[Code] AS [CountryCode], C.[Name] AS [CountryName], S.[Id] AS [SportId], C.[ImageCode] AS [ImageCode],
		SUBSTRING(S.[Name], 0, 50) AS [SportName], E.[EventCount],
		E.[BetTypeGroupName] AS [BetTypeGroupName],
		E.[BetTypeGroupId] as [BetTypeGroupId],
		ISNULL(E.[BetTypeGroupOrdering], 9999) AS [BetTypeGroupOrdering]
	FROM 
	(
		SELECT [LeagueId], [EventCount], [BetTypeGroupId], [BetTypeGroupName], [BetTypeGroupOrdering]
		FROM @Events
	) AS E
	INNER JOIN dbo.[League] AS L WITH (NOLOCK) ON L.[Id] = E.[LeagueId]
	INNER JOIN [dbo].[Country] AS C WITH(NOLOCK) ON C.[Code] = L.[CountryCode]
	INNER JOIN Sport S WITH(NOLOCK) ON L.SportID = S.ID
	OPTION (FORCE ORDER)

	--ADD TABLE SportSortSettings, CountrySortSettings, LeagueSortSettings !!!
END
