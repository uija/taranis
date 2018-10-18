-- Battery configurations with min and max values per cell
local batteryConfig = {}
  batteryConfig.nimh = {}
    batteryConfig.nimh.min = 1.2
    batteryConfig.nimh.max = 1.5
  batteryConfig.lipo = {}
    batteryConfig.lipo.min = 3.5
    batteryConfig.lipo.max = 4.2

-- Define, what battery we use
local battery = batteryConfig.lipo;
-- How many cells
local cells = 1;

-- // Store some local variables to reuse them
local modelInfo = {}

local height = 0;
local hmin = 0;
local hmax = 0;
local rxbt = 0;
local speed = 0;
local smin = 0;
local smax = 0;
local rssimin = 0;
local rssimax = 0;
local rssi = 0;

-- is called by run and background to fetch data from telemetry
-- calculates min and max rssi to be able to display it
local function getData()
  height = getValue( "Alt");
  hmin = getValue( "Alt-");
  hmax = getValue( "Alt+");

  rxbt = getValue( "RxBt");

  speed = getValue( "VSpd");
  smin = getValue( "VSpd-");
  smax = getValue( "VSpd+");

  rssi = getValue( "RSSI");
  if rssi > 10 then
    if rssimin == 0 or rssi < rssimin then
      rssimin = rssi;
    end
    if rssi > rssimax then
      rssimax = rssi
    end
  end
end

local function getPercent( value, min, max)
  local range = max - min;
  local val = value - min;
  if val < 0 then
    return 0
  end
  local v = 100 / range * val;
  if v > 100 then
    return 100
  end
  return v
end

local function batteryPercentage( value)
  return getPercent( value, battery.min*cells, battery.max*cells);
end

local function getRssiPercentage( rssi)
  return getPercent( rssi, 40, 100);
end

local function drawBatteryGauge( x)
  local y = 12;
  local w = 15;
  local offset = 3;
  lcd.drawRectangle( x+offset, y+1, w, 42, SOLID);

  local percent = batteryPercentage( rxbt);
  local height = math.ceil(38 / 100 * percent);
  local start = 41 - height;

  lcd.drawFilledRectangle( x+offset+2, y+start, w-4, height);
  lcd.drawLine( x+offset+2, y, x+offset+w-3, y, SOLID, FORCE)
  lcd.drawNumber( x, y+44, rxbt*100, PREC2+SMLSIZE);
  lcd.drawText( lcd.getLastPos(), y+44, "V", SMLSIZE);
  return 22;
end

local function drawSpacer( x)
  local padding = 3
  lcd.drawLine( x+padding, 9, x+padding, 63, DOTTED, FORCE);
  return padding * 2 + 1;
end

local function drawHeight( x)
  local y = 12;
  lcd.drawText( x, y, "Height");
  lcd.drawNumber( x, y+12, height*10, PREC1+MIDSIZE);
  lcd.drawText( lcd.getLastPos(), y+17, "m", SMLSIZE);

  lcd.drawLine( x+2, y+30, x+46, y+30, DOTTED, FORCE)

  lcd.drawText( x, y+35, "Min:", SMLSIZE);
  lcd.drawNumber( x+20, y+35, hmin*10, PREC1+SMLSIZE);
  lcd.drawText( lcd.getLastPos(), y+35, "m", SMLSIZE);
  lcd.drawText( x, y+45, "Max:", SMLSIZE);
  lcd.drawNumber( x+20, y+45, hmax*10, PREC1+SMLSIZE);
  lcd.drawText( lcd.getLastPos(), y+45, "m", SMLSIZE);
  return 48;
end

local function drawVSpeed( x)
  local y = 12;
  lcd.drawText( x, y, "V-Speed");
  lcd.drawNumber( x, y+12, speed*10, PREC1+MIDSIZE);
  lcd.drawText( lcd.getLastPos(), y+17, "m/s", SMLSIZE);

  lcd.drawLine( x+2, y+30, x+56, y+30, DOTTED, FORCE)

  lcd.drawText( x, y+35, "Min:", SMLSIZE);
  lcd.drawNumber( x+20, y+35, smin*10, PREC1+SMLSIZE);
  lcd.drawText( lcd.getLastPos(), y+35, "m/s", SMLSIZE);
  lcd.drawText( x, y+45, "Max:", SMLSIZE);
  lcd.drawNumber( x+20, y+45, smax*10, PREC1+SMLSIZE);
  lcd.drawText( lcd.getLastPos(), y+45, "m/2", SMLSIZE);
  return 58;
end
local function drawTimers( x)
  local y = 12;
  lcd.drawText( x, y, "Timers")
  local t1 = getFieldInfo( "timer1");
  local t2 = getFieldInfo( "timer2");
  lcd.drawText( x, y+15, t1.name, SMLSIZE);
  lcd.drawTimer( x, y+22, getValue( "timer1"), TIMEHOUR);
  lcd.drawText( x, y+35, t2.name, SMLSIZE);
  lcd.drawTimer( x, y+43, getValue( "timer2"), TIMEHOUR);

  return 48;
end

local function drawHeadline()
  lcd.drawText( 1, 1, modelInfo.name, SMLSIZE)
  lcd.drawText( lcd.getLastPos() + 5, 1, " ", SMLSIZE);
  lcd.drawNumber( lcd.getLastPos() + 5, 1, getValue( "tx-voltage")*100, PREC2+SMLSIZE);
  lcd.drawText( lcd.getLastPos(), 1, "V", SMLSIZE);
  lcd.drawText( lcd.getLastPos() + 5, 1, " ", SMLSIZE);
  lcd.drawNumber( lcd.getLastPos()+5, 1, rssi, SMLSIZE)
  lcd.drawText( lcd.getLastPos()+1, 1, " (", SMLSIZE);
  lcd.drawNumber( lcd.getLastPos(), 1, rssimin, SMLSIZE)
  lcd.drawText( lcd.getLastPos(), 1, " - ", SMLSIZE);
  lcd.drawNumber( lcd.getLastPos(), 1, rssimax, SMLSIZE)
  lcd.drawText( lcd.getLastPos()+1, 1, ")", SMLSIZE);
  lcd.drawText( lcd.getLastPos(), 1, "db", SMLSIZE);
  lcd.drawLine( 0, 8, 212, 8, DOTTED, FORCE)
end

local function run_func( e)
  getData();
  lcd.clear()

  drawHeadline();

  local x = 3;
  x = x + drawBatteryGauge( x);
  x = x + drawSpacer( x);
  x = x + drawHeight( x);
  x = x + drawSpacer( x);
  x = x + drawVSpeed( x);
  x = x + drawSpacer( x);
  x = x + drawTimers( x);
end

local function init_func()
  modelInfo = model.getInfo();
end

local function bg_func()
  getData();
end


return { run=run_func, background=bg_func, init=init_func }
