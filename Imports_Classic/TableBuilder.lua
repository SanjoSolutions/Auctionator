local ColumnFramePoolCollection = CreateFramePoolCollection();

local ColumnWidthConstraints = {
	Fill = 1, -- Width will be distributed by available space.
	Fixed = 2, -- Width is specified when initializing the column.
};

-- Any row or cell is expected to initialize itself in terms of the row data. The dataIndex is provided
-- in case the derived mixin needs to make additional CAPI calls involving it's relative index. The row
-- data may also be needed for a tooltip, so it will be assigned to the row and cells on update.
AuctionHouseHelperRetailImportTableBuilderElementMixin = {};

--Derive
function AuctionHouseHelperRetailImportTableBuilderElementMixin:Init(...)
end

--Derive
function AuctionHouseHelperRetailImportTableBuilderElementMixin:Populate(rowData, dataProviderKey)
end

AuctionHouseHelperRetailImportTableBuilderCellMixin = CreateFromMixins(AuctionHouseHelperRetailImportTableBuilderElementMixin);

--Derive
function AuctionHouseHelperRetailImportTableBuilderCellMixin:OnLineEnter()
end

--Derive
function AuctionHouseHelperRetailImportTableBuilderCellMixin:OnLineLeave()
end


AuctionHouseHelperRetailImportTableBuilderRowMixin = CreateFromMixins(AuctionHouseHelperRetailImportTableBuilderElementMixin);

--Derive
function AuctionHouseHelperRetailImportTableBuilderRowMixin:OnLineEnter()
end

--Derive
function AuctionHouseHelperRetailImportTableBuilderRowMixin:OnLineLeave()
end


function AuctionHouseHelperRetailImportTableBuilderRowMixin:OnEnter()
	self:OnLineEnter();
	for i, cell in ipairs(self.cells) do
		cell:OnLineEnter();
	end
end

function AuctionHouseHelperRetailImportTableBuilderRowMixin:OnLeave()
	self:OnLineLeave();
	for i, cell in ipairs(self.cells) do
		cell:OnLineLeave();
	end
end

-- Defines an entire column within the table builder, by default a column's sizing constraints are set to fill.
AuctionHouseHelperRetailImportTableBuilderColumnMixin = {};
function AuctionHouseHelperRetailImportTableBuilderColumnMixin:Init(table)
	self.cells = {};
	self.table = table;

	local fillCoefficient = 1.0;
	local padding = 0;
	self:SetFillConstraints(fillCoefficient, padding);
end

-- Constructs the header frame with an optional initializer.
function AuctionHouseHelperRetailImportTableBuilderColumnMixin:ConstructHeader(templateType, template, ...)
	local frame = self.table:ConstructHeader(templateType, template);
	self.headerFrame = frame;
	if frame.Init then
		frame:Init(...);
	end
	frame:Show();
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:Reset()
	for row, cell in pairs(self.cells) do
		self.pool:Release(cell);
		tDeleteItem(row.cells, cell);
	end
	self.cells = {};
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:RemoveRow(row)
	local cell = self.cells[row];
	self.cells[row] = nil;
	self.pool:Release(cell);
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:ConstructCell(row, rowData, dataProviderKey)
	local cell = self.pool:Acquire();
	self.cells[row] = cell;

	if cell.Init then
		cell:Init(unpack(self.args));
	end

	if cell.Populate then
		cell.rowData = rowData;
		cell:Populate(rowData, dataProviderKey);
	end

	cell:Show();
	return cell;
end

-- Constructs cells corresponding to each row with an optional initializer.
function AuctionHouseHelperRetailImportTableBuilderColumnMixin:ConstructCells(templateType, template, ...)
	self.args = {...};

	self.pool = ColumnFramePoolCollection:GetOrCreatePool(templateType, nil, template);
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetFillCoefficient()
	return self.fillCoefficient;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:SetFillCoefficient(fillCoefficient)
	self.fillCoefficient = fillCoefficient;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetPadding()
	return self.padding;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:SetPadding(padding)
	self.padding = padding;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetCellPadding()
	return self.leftCellPadding or 0, self.rightCellPadding or 0;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:SetCellPadding(leftCellPadding, rightCellPadding)
	self.leftCellPadding = leftCellPadding;
	self.rightCellPadding = rightCellPadding;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetHeaderFrame()
	return self.headerFrame;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:SetHeaderFrame(headerFrame)
	self.headerFrame = headerFrame;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetWidthConstraints()
	return self.widthConstraints;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetFixedWidth()
	return self.fixedWidth;
end

-- A header frame for the column is expected to be constructed or assigned prior to calling this.
-- See ConstructHeader() or SetHeaderFrame().
function AuctionHouseHelperRetailImportTableBuilderColumnMixin:ConstrainToHeader(padding)
	local header = self:GetHeaderFrame();
	assert(header, "ConstrainToHeader() called with a nil header frame. Use ConstructHeader() or assign one with SetHeaderFrame(), or use SetFixedConstraints to have a headerless column.");
	self:SetFixedConstraints(header:GetWidth(), padding or 0);
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:SetFixedConstraints(fixedWidth, padding)
	self.widthConstraints = ColumnWidthConstraints.Fixed;
	self.fixedWidth = fixedWidth;
	self:SetFillCoefficient(0);
	self:SetPadding(padding or 0);
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:SetFillConstraints(fillCoefficient, padding)
	self.widthConstraints = ColumnWidthConstraints.Fill;
	self.fixedWidth = 0;
	self:SetFillCoefficient(fillCoefficient);
	self:SetPadding(padding or 0);
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:SetCalculatedWidth(calculatedWidth)
	self.calculatedWidth = calculatedWidth;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetCalculatedWidth()
	return self.calculatedWidth;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetCellWidth()
	local leftCellPadding, rightCellPadding = self:GetCellPadding();
	return (self.calculatedWidth - leftCellPadding) - rightCellPadding;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetFullWidth()
	return self:GetCalculatedWidth() + self:GetPadding();
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:SetDisplayUnderPreviousHeader(displayUnderPreviousHeader)
	self.displayUnderPreviousHeader = displayUnderPreviousHeader;
end

function AuctionHouseHelperRetailImportTableBuilderColumnMixin:GetDisplayUnderPreviousHeader()
	return self.displayUnderPreviousHeader;
end

-- Constructs a table of frames within an existing set of row frames. These row frames could originate from
-- a hybrid scroll frame or statically fixed set. To populate the table, assign a data provider (CAPI or lua function)
-- that can retrieve an object by index (number).
AuctionHouseHelperRetailImportTableBuilderMixin = {};
function AuctionHouseHelperRetailImportTableBuilderMixin:Init()
	self.rows = {};
	self.columns = {};
	self.leftMargin = 0;
	self.rightMargin = 0;
	self.columnHeaderOverlap = 0;
	self.tableWidth = 0;
	self.headerPoolCollection = CreateFramePoolCollection();
end

function AuctionHouseHelperRetailImportTableBuilderMixin:GetDataProvider()
	return self.dataProvider;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:SetDataProvider(dataProvider)
	self.dataProvider = dataProvider;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:GetDataProviderData(dataProviderKey)
	local dataProvider = self:GetDataProvider();
	return dataProvider and dataProvider(dataProviderKey) or nil;
end

-- Controls the margins of the left-most and right-most columns within the table.
function AuctionHouseHelperRetailImportTableBuilderMixin:SetTableMargins(leftMargin, rightMargin)
	rightMargin = rightMargin or leftMargin; -- Use leftMargin as the default for both.
	self.leftMargin = leftMargin;
	self.rightMargin = rightMargin;
end

-- Column headers overlap to make a consistent display.
function AuctionHouseHelperRetailImportTableBuilderMixin:SetColumnHeaderOverlap(columnHeaderOverlap)
	self.columnHeaderOverlap = columnHeaderOverlap;
end

-- Can be used to set the table width, particularly if no header frames are involved.
function AuctionHouseHelperRetailImportTableBuilderMixin:SetTableWidth(tableWidth)
	self.tableWidth = tableWidth;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:GetTableWidth()
	return self.tableWidth;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:GetTableMargins()
	return self.leftMargin, self.rightMargin;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:GetColumnHeaderOverlap()
	return self.columnHeaderOverlap;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:GetColumns()
	return self.columns;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:GetHeaderContainer()
	return self.headerContainer;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:SetHeaderContainer(headerContainer)
	assert(headerContainer, "SetHeaderContainer() with a nil header container. Use ConstructHeader() or assign one with SetHeaderFrame(), or use SetFixedConstraints to have a headerless column.");
	self.headerContainer = headerContainer;
	self:SetTableWidth(headerContainer:GetWidth());
end

function AuctionHouseHelperRetailImportTableBuilderMixin:GetHeaderPoolCollection()
	return self.headerPoolCollection;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:EnumerateHeaders()
	return self.headerPoolCollection:EnumerateActive();
end

function AuctionHouseHelperRetailImportTableBuilderMixin:ConstructHeader(templateType, template)
	local headerContainer = self:GetHeaderContainer();
	assert(headerContainer ~= nil, "A header container must be set with AuctionHouseHelperRetailImportTableBuilderMixin:SetHeaderContainer before adding column headers.")
	local headerPoolCollection = self:GetHeaderPoolCollection();
	local pool = headerPoolCollection:GetOrCreatePool(templateType, headerContainer, template);
	return pool:Acquire(template);
end

function AuctionHouseHelperRetailImportTableBuilderMixin:Arrange()
	local columns = self:GetColumns();
	if columns and #columns > 0 then
		self:CalculateColumnSpacing();
		self:ArrangeHeaders();
	end

	for columnIndex, column in ipairs(self.columns) do
		column:Reset();
	end

	-- Repopulate cells for each row in case the column information changed.
	for index, row in ipairs(self.rows) do
		--assert(TableIsEmpty(row.cells));
		for columnIndex, column in ipairs(self.columns) do
			--assert(row.rowData);
			local cell = column:ConstructCell(row, row.rowData, columnIndex);
			table.insert(row.cells, cell);
		end
	
		self:ArrangeCells(row);
	end
end

function AuctionHouseHelperRetailImportTableBuilderMixin:Reset()
	self:GetHeaderPoolCollection():ReleaseAll();

	for columnIndex, column in ipairs(self.columns) do
		column:Reset();
	end
	self.columns = {};
end

function AuctionHouseHelperRetailImportTableBuilderMixin:AddRow(row, dataProviderKey)
	local rowData = self:GetDataProviderData(dataProviderKey);	
	if not rowData then
		return;
	end
	row.rowData = rowData;
	table.insert(self.rows, row);

	if row.Populate then
		row:Populate(rowData, dataProviderKey);
	end

	row.cells = {};
	for columnIndex, column in ipairs(self.columns) do
		local cell = column:ConstructCell(row, rowData, columnIndex);
		table.insert(row.cells, cell);
	end

	self:ArrangeCells(row);
end

function AuctionHouseHelperRetailImportTableBuilderMixin:RemoveRow(row)
	local deleted = tDeleteItem(self.rows, row) > 0;
	if not deleted then
		return;
	end

	for columnIndex, column in ipairs(self.columns) do
		column:RemoveRow(row);
	end

	row.rowData = nil;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:ArrangeCells(row)
	local columns = self:GetColumns();
	if #columns == 0 then
		return;
	end

	local height = row:GetHeight();
	local leftMargin, rightMargin = self:GetTableMargins();

	local column = columns[1];
	local cell = row.cells[1];
	cell:SetParent(row);
	cell:SetHeight(height);
	local leftCellPadding, rightCellPadding = column:GetCellPadding();
	
	self:ArrangeHorizontally(cell, row, column:GetCellWidth(), "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", leftMargin + leftCellPadding);
	
	local previousCell = cell;
	local previousRightCellPadding = rightCellPadding;
	for columnIndex = 2, #columns do
		column = columns[columnIndex];
		local cell = row.cells[columnIndex];
		cell:SetParent(row);
		cell:SetHeight(height);
		leftCellPadding, rightCellPadding = column:GetCellPadding();

		self:ArrangeHorizontally(cell, previousCell, column:GetCellWidth(), "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", column:GetPadding() + leftCellPadding + previousRightCellPadding);
		previousCell = cell;
		previousRightCellPadding = rightCellPadding;
	end
end

function AuctionHouseHelperRetailImportTableBuilderMixin:AddColumn()
	local column = CreateAndInitFromMixin(AuctionHouseHelperRetailImportTableBuilderColumnMixin, self);
	tinsert(self.columns, column);
	return column;
end

function AuctionHouseHelperRetailImportTableBuilderMixin:CalculateColumnSpacing()
	-- The arrangement of frames is daisy-chained left to right. The margin on the left side
	-- is created by adding the margin to it's anchor offset, and the margin on the right side
	-- is created by subtracting space from the remaining fill space.
	local columns = self:GetColumns();
	local paddingTotal = 0;
	local fillCoefficientTotal = 0;
	local fixedWidthTotal = 0;
	for columnIndex, column in ipairs(columns) do
		if column:GetWidthConstraints() == ColumnWidthConstraints.Fill then
			fillCoefficientTotal = fillCoefficientTotal + column:GetFillCoefficient();
		else
			fixedWidthTotal = fixedWidthTotal + column:GetFixedWidth();
		end

		paddingTotal = paddingTotal + column:GetPadding();
	end

	local tableWidth = self:GetTableWidth();
	local leftMargin, rightMargin = self:GetTableMargins();
	local fillWidthTotal = tableWidth - paddingTotal - (leftMargin + rightMargin) - fixedWidthTotal;
	for k, column in pairs(columns) do
		if fillCoefficientTotal > 0 and column:GetWidthConstraints() == ColumnWidthConstraints.Fill then
			local fillRatio = column:GetFillCoefficient() / fillCoefficientTotal;
			local width = fillRatio * fillWidthTotal;
			column:SetCalculatedWidth(width);
		else
			local width = column:GetFixedWidth();
			column:SetCalculatedWidth(width);
		end
	end
end

function AuctionHouseHelperRetailImportTableBuilderMixin:ArrangeHorizontally(frame, relativeTo, width, pointTop, pointRelativeTop, pointBottom, pointRelativeBottom, xOffset)
	frame:SetPoint(pointTop, relativeTo, pointRelativeTop, xOffset, 0);
	frame:SetPoint(pointBottom, relativeTo, pointRelativeBottom, xOffset, 0);
	frame:SetWidth(width);
end

function AuctionHouseHelperRetailImportTableBuilderMixin:ArrangeHeaders()
	local headerOverlap = self:GetColumnHeaderOverlap();
	local leftMargin, rightMargin = self:GetTableMargins();
	local columns = self:GetColumns();

	-- Any trailing columns without headers should add to the width of the last column with a header.
	local numColumns = #columns;
	local lastActiveHeaderIndex = numColumns;
	local trailingWidth = 0;
	for i, column in ipairs(columns) do
		if column:GetHeaderFrame() then
			trailingWidth = 0;
			lastActiveHeaderIndex = i;
		else
			trailingWidth = trailingWidth + column:GetFullWidth();
		end
	end

	local previousHeader = nil;
	local accumulatedWidth = 0;
	local columnIndex = 1;

	while columnIndex <= numColumns do
		local column = columns[columnIndex];
		accumulatedWidth = accumulatedWidth + column:GetCalculatedWidth();

		local isLastIndex = columnIndex == lastActiveHeaderIndex;
		local header = column:GetHeaderFrame();
		if header then
			if isLastIndex then
				accumulatedWidth = accumulatedWidth + trailingWidth;
			else
				for j = columnIndex + 1, #columns do
					local nextColumn = columns[j];
					if nextColumn:GetDisplayUnderPreviousHeader() then
						columnIndex = columnIndex + 1;
						accumulatedWidth = accumulatedWidth + nextColumn:GetFullWidth();
					else
						break;
					end
				end
			end

			if previousHeader == nil then
				self:ArrangeHorizontally(header, header:GetParent(), accumulatedWidth, "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", leftMargin);
			else
				self:ArrangeHorizontally(header, previousHeader, accumulatedWidth + headerOverlap, "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", column:GetPadding() - headerOverlap);
			end

			accumulatedWidth = 0;
			previousHeader = header;
		end

		if isLastIndex then
			break;
		end

		columnIndex = columnIndex + 1;
	end
end

-- ... are additional mixins
function AuctionHouseHelperRetailImportCreateTableBuilder(rows, ...)
	local tableBuilder = CreateAndInitFromMixin(AuctionHouseHelperRetailImportTableBuilderMixin, rows);
	Mixin(tableBuilder, ...);
	return tableBuilder;
end
