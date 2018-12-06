SET NOCOUNT ON

DECLARE @Entities TABLE (
	EntityName varchar(250)
)

DECLARE @Dependencies TABLE (
	PKEntity varchar(250),
	FKEntity varchar(250)
)

DECLARE @SortedEntities TABLE (
	Id int identity(1,1),
	EntityName nvarchar(250)
)

INSERT INTO @Entities (EntityName)
SELECT name FROM sys.objects WHERE type NOT IN ('S')

INSERT INTO @Dependencies (PKEntity,FKEntity)
SELECT PKEntity.table_name as PKEntity, fktable.table_name as FKEntity
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS refcon
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS fktable ON fktable.CONSTRAINT_NAME = refcon.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS PKEntity ON PKEntity.CONSTRAINT_NAME = refcon.UNIQUE_CONSTRAINT_NAME
UNION
SELECT referenced_entity_name, OBJECT_NAME(referencing_id)
FROM SYS.sql_expression_dependencies AS sed  
INNER JOIN sys.objects AS o ON sed.referencing_id = o.object_id  

DECLARE @CurrentTable varchar(100)
DECLARE @DependantTable varchar(100)
DECLARE @PreviousRelatedTable varchar(100)

SET @PreviousRelatedTable = ''
SET @CurrentTable = (SELECT TOP 1 EntityName FROM @Entities)

WHILE @CurrentTable != ''
BEGIN

	SET @DependantTable = ''

	SELECT TOP 1 @DependantTable = PKEntity
	FROM @Dependencies
	WHERE FKEntity = @CurrentTable AND PKEntity != @CurrentTable

	-- If this table does not have any dependencies on other table then add it to the sorted Entities table and then remove it from the Entities list.
	-- Else if a dependant table was found then move on to that table for the next loop
	IF @DependantTable = ''
	BEGIN

		INSERT INTO @SortedEntities (EntityName) VALUES (@CurrentTable)

		--Remove all references to the removed table to allow object higher up in the hierarchy to be added later
		DELETE FROM @Dependencies WHERE PKEntity = @CurrentTable

		--Remove the current table from the Entities list
		DELETE FROM @Entities WHERE EntityName = @CurrentTable 

		--Move on to the next table
		SET @CurrentTable = ''
		SET @CurrentTable = (SELECT TOP 1 EntityName FROM @Entities)
	END
	ELSE
	BEGIN
		SET @PreviousRelatedTable = @CurrentTable
		SET @CurrentTable = @DependantTable
	END
END

SELECT id, EntityName as entity FROM @SortedEntities ORDER BY id