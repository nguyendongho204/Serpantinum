-- Layout luoi (grid): chia cua so thanh 2 cot, so hang tu dong.
-- 1 cua so -> 1 o; 2 -> 1x2; 3 -> 2 cot x 2 hang (o cuoi bo trong); 4 -> 2x2.
-- Dung: Super+G de chuyen workspace hien tai sang layout nay.

local function grid_recalculate(ctx)
  local targets = ctx.targets
  local n = #targets
  if n == 0 then return end
  local cols = (n == 1) and 1 or 2
  local rows = math.ceil(n / cols)
  for i = 1, n do
    local t = targets[i]
    if t then
      t:set_box(ctx.grid_cell(i - 1, cols, rows))
    end
  end
end

hl.layout.register("grid", { recalculate = grid_recalculate })

-- Layout xep doc: 1 cot, moi cua so 1 hang (2 cua so -> tren/duoi).
local function stack_recalculate(ctx)
  local targets = ctx.targets
  local n = #targets
  if n == 0 then return end
  for i = 1, n do
    local t = targets[i]
    if t then
      t:set_box(ctx.grid_cell(i - 1, 1, n))
    end
  end
end

hl.layout.register("stack", { recalculate = stack_recalculate })
