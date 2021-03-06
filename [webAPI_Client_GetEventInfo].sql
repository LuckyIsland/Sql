USE [DB_A2CB54_11]
GO
/****** Object:  StoredProcedure [dbo].[webAPI_Client_GetEventInfo]    Script Date: 12/8/2017 9:19:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[webAPI_Client_GetEventInfo]
	@LeagueIds VARCHAR(MAX),
	@EventIds varchar(max),
	@LanguageCode CHAR(2),
	@Day DATETIME,
	@Bias INT,
	@Duration INT,
	@BettingLineTemplateID INT
AS
BEGIN
	--DECLARE 
	--	@LeagueIds VARCHAR(MAX),
	--	@EventIds varchar(max) = '1|3|10|15',
	--	@LanguageCode CHAR(2) = 'EN',
	--	@Day DATETIME = NULL,
	--	@Bias INT = NULL,
	--	@Duration INT = NULL,
	--	@BettingLineTemplateID INT = 1

	SET NOCOUNT ON;

	IF @BettingLineTemplateID IS NULL
		SET @BettingLineTemplateID = 1

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

	SELECT
		L.[SportId], S.[Name] AS [SportName],
		C.[Code] AS [CountryCode], C.[Name] as [CountryName],
		L.[Id] AS [LeagueId], L.[Name] AS [LeagueName],
		E.[Id] AS [EventID], E.[EventCode], E.[EventType], E.[EventName] AS [EventName],
		DATEADD(MINUTE, @Bias,E.[EventDate]) AS [EventDate], DATEDIFF(MINUTE, GETUTCDATE(), E.[EventDate]) AS [Interval],
		E.[HomeId], TH.[Name] AS [HomeName],
		E.[GuestId], TG.[Name] AS [GuestName]
	FROM dbo.[Event] E WITH(NOLOCK) 
	INNER JOIN dbo.[League] L WITH(NOLOCK) ON E.[LeagueId] = L.[Id]
	INNER JOIN dbo.[Sport] S WITH(NOLOCK) ON L.[SportID] = S.[Id]
	INNER JOIN dbo.[Country] C WITH(NOLOCK) ON C.[Code] = E.[CountryCode]
	LEFT LOOP JOIN dbo.[Team] AS TH WITH(NOLOCK) ON TH.[Id] = E.[HomeId]
	LEFT LOOP JOIN dbo.[Team] AS TG WITH(NOLOCK) ON TG.[Id] = E.[GuestId]
	WHERE E.[EventDate] > GETUTCDATE() AND E.[Status] = 0
		AND (@LeagueIds IS NULL OR E.LeagueID IN (SELECT [id_value] FROM dbo.[ConvertToTable](@LeagueIds, '|')))
		AND (@EventIds IS NULL OR (E.[Id] IN (SELECT [id_value] FROM dbo.[ConvertToTable](@EventIds, '|'))))
		AND (@Day IS NULL OR (E.[EventDate] < DATEADD(MINUTE, @Bias * -1, DATEADD(DAY,1,@Day))
		AND E.[EventDate] >= DATEADD(MINUTE, @Bias * -1, @Day)))
		AND (@Duration IS NULL OR E.[EventDate] < DATEADD(MINUTE, @Duration, GETUTCDATE()))
		AND (@BettingLineTemplateID = 1 OR E.[ID] IN (SELECT [EventID] FROM dbo.[BettingLineTemplateEvents] BLTL WITH(NOLOCK) WHERE BLTL.[BettingLineTemplateID] = @BettingLineTemplateID))
	OPTION (FORCE ORDER)
END
