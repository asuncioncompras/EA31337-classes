//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                       Copyright 2016-2021, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Includes.
#include "../Indicator.mqh"

#ifndef __MQL4__
// Defines global functions (for MQL4 backward compability).
double iIchimoku(string _symbol, int _tf, int _ts, int _ks, int _ssb, int _mode, int _shift) {
  return Indi_Ichimoku::iIchimoku(_symbol, (ENUM_TIMEFRAMES)_tf, _ts, _ks, _ssb, _mode, _shift);
}
#endif

#ifndef __MQLBUILD__
// Indicator constants.
// @docs
// - https://www.mql5.com/en/docs/constants/indicatorconstants/lines
// Identifiers of indicator lines permissible when copying values of iIchimoku().
#define TENKANSEN_LINE 0    // Tenkan-sen line.
#define KIJUNSEN_LINE 1     // Kijun-sen line.
#define SENKOUSPANA_LINE 2  // Senkou Span A line.
#define SENKOUSPANB_LINE 3  // Senkou Span B line.
#define CHIKOUSPAN_LINE 4   // Chikou Span line.
#endif

// Enums.
// Ichimoku Kinko Hyo identifiers used in Ichimoku indicator.
enum ENUM_ICHIMOKU_LINE {
#ifdef __MQL4__
  LINE_TENKANSEN = MODE_TENKANSEN,      // Tenkan-sen line.
  LINE_KIJUNSEN = MODE_KIJUNSEN,        // Kijun-sen line.
  LINE_SENKOUSPANA = MODE_SENKOUSPANA,  // Senkou Span A line.
  LINE_SENKOUSPANB = MODE_SENKOUSPANB,  // Senkou Span B line.
  LINE_CHIKOUSPAN = MODE_CHIKOUSPAN,    // Chikou Span line.
#else
  LINE_TENKANSEN = TENKANSEN_LINE,      // Tenkan-sen line.
  LINE_KIJUNSEN = KIJUNSEN_LINE,        // Kijun-sen line.
  LINE_SENKOUSPANA = SENKOUSPANA_LINE,  // Senkou Span A line.
  LINE_SENKOUSPANB = SENKOUSPANB_LINE,  // Senkou Span B line.
  LINE_CHIKOUSPAN = CHIKOUSPAN_LINE,    // Chikou Span line.
#endif
  FINAL_ICHIMOKU_LINE_ENTRY,
};

// Structs.
struct IchimokuParams : IndicatorParams {
  unsigned int tenkan_sen;
  unsigned int kijun_sen;
  unsigned int senkou_span_b;
  // Struct constructors.
  void IchimokuParams(unsigned int _ts, unsigned int _ks, unsigned int _ss_b, int _shift = 0)
      : tenkan_sen(_ts), kijun_sen(_ks), senkou_span_b(_ss_b) {
    itype = INDI_ICHIMOKU;
    max_modes = FINAL_ICHIMOKU_LINE_ENTRY;
    shift = _shift;
    SetDataValueType(TYPE_DOUBLE);
  };
  void IchimokuParams(IchimokuParams &_params, ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
    this = _params;
    tf = _tf;
  };
};

/**
 * Implements the Ichimoku Kinko Hyo indicator.
 */
class Indi_Ichimoku : public Indicator {
 protected:
  IchimokuParams params;

 public:
  /**
   * Class constructor.
   */
  Indi_Ichimoku(IchimokuParams &_p)
      : params(_p.tenkan_sen, _p.kijun_sen, _p.senkou_span_b), Indicator((IndicatorParams)_p) {
    params = _p;
  }
  Indi_Ichimoku(IchimokuParams &_p, ENUM_TIMEFRAMES _tf)
      : params(_p.tenkan_sen, _p.kijun_sen, _p.senkou_span_b), Indicator(INDI_ICHIMOKU, _tf) {
    params = _p;
  }

  /**
   * Returns the indicator value.
   *
   * @param
   * _mode int
   * - MT4: 1 - MODE_TENKANSEN, 2 - MODE_KIJUNSEN, 3 - MODE_SENKOUSPANA, 4 - MODE_SENKOUSPANB, 5 - MODE_CHIKOUSPAN
   * - MT5: 0 - TENKANSEN_LINE, 1 - KIJUNSEN_LINE, 2 - SENKOUSPANA_LINE, 3 - SENKOUSPANB_LINE, 4 - CHIKOUSPAN_LINE
   * @docs
   * - https://docs.mql4.com/indicators/iichimoku
   * - https://www.mql5.com/en/docs/indicators/iichimoku
   */
  static double iIchimoku(string _symbol, ENUM_TIMEFRAMES _tf, int _tenkan_sen, int _kijun_sen, int _senkou_span_b,
                          int _mode, int _shift = 0, Indicator *_obj = NULL) {
#ifdef __MQL4__
    return ::iIchimoku(_symbol, _tf, _tenkan_sen, _kijun_sen, _senkou_span_b, _mode, _shift);
#else  // __MQL5__
    int _handle = Object::IsValid(_obj) ? _obj.GetState().GetHandle() : NULL;
    double _res[];
    ResetLastError();
    if (_handle == NULL || _handle == INVALID_HANDLE) {
      if ((_handle = ::iIchimoku(_symbol, _tf, _tenkan_sen, _kijun_sen, _senkou_span_b)) == INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return EMPTY_VALUE;
      } else if (Object::IsValid(_obj)) {
        _obj.SetHandle(_handle);
      }
    }
    if (Terminal::IsVisualMode()) {
      // To avoid error 4806 (ERR_INDICATOR_DATA_NOT_FOUND),
      // we check the number of calculated data only in visual mode.
      int _bars_calc = BarsCalculated(_handle);
      if (GetLastError() > 0) {
        return EMPTY_VALUE;
      } else if (_bars_calc <= 2) {
        SetUserError(ERR_USER_INVALID_BUFF_NUM);
        return EMPTY_VALUE;
      }
    }
    if (CopyBuffer(_handle, _mode, _shift, 1, _res) < 0) {
      return EMPTY_VALUE;
    }
    return _res[0];
#endif
  }

  /**
   * Returns the indicator's value.
   */
  double GetValue(ENUM_ICHIMOKU_LINE _mode, int _shift = 0) {
    ResetLastError();
    istate.handle = istate.is_changed ? INVALID_HANDLE : istate.handle;
    double _value = Indi_Ichimoku::iIchimoku(GetSymbol(), GetTf(), GetTenkanSen(), GetKijunSen(), GetSenkouSpanB(),
                                             _mode, _shift, GetPointer(this));
    istate.is_ready = _LastError == ERR_NO_ERROR;
    istate.is_changed = false;
    return _value;
  }

  /**
   * Returns the indicator's struct value.
   */
  IndicatorDataEntry GetEntry(int _shift = 0) {
    long _bar_time = GetBarTime(_shift);
    unsigned int _position;
    IndicatorDataEntry _entry(params.max_modes);
    if (idata.KeyExists(_bar_time, _position)) {
      _entry = idata.GetByPos(_position);
    } else {
      _entry.timestamp = GetBarTime(_shift);
#ifdef __MQL4__
      // In MQL4 value of LINE_TENKANSEN is 1 (not 0 as in MQL5),
      // so we are duplicating it.
      _entry.values[0] = GetValue(LINE_TENKANSEN, _shift);
#endif
      _entry.values[LINE_TENKANSEN] = GetValue(LINE_TENKANSEN, _shift);
      _entry.values[LINE_KIJUNSEN] = GetValue(LINE_KIJUNSEN, _shift);
      _entry.values[LINE_SENKOUSPANA] = GetValue(LINE_SENKOUSPANA, _shift);
      _entry.values[LINE_SENKOUSPANB] = GetValue(LINE_SENKOUSPANB, _shift);
      _entry.values[LINE_CHIKOUSPAN] = GetValue(LINE_CHIKOUSPAN, _shift + 26);
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID,
                     !_entry.HasValue((double)NULL) && !_entry.HasValue(EMPTY_VALUE) && _entry.IsGt(0));
      if (_entry.IsValid()) idata.Add(_entry, _bar_time);
    }
    return _entry;
  }

  /**
   * Returns the indicator's entry value.
   */
  MqlParam GetEntryValue(int _shift = 0, int _mode = 0) {
    MqlParam _param = {TYPE_DOUBLE};
    GetEntry(_shift).values[_mode].Get(_param.double_value);
    return _param;
  }

  /* Getters */

  /**
   * Get period of Tenkan-sen line.
   */
  unsigned int GetTenkanSen() { return params.tenkan_sen; }

  /**
   * Get period of Kijun-sen line.
   */
  unsigned int GetKijunSen() { return params.kijun_sen; }

  /**
   * Get period of Senkou Span B line.
   */
  unsigned int GetSenkouSpanB() { return params.senkou_span_b; }

  /* Setters */

  /**
   * Set period of Tenkan-sen line.
   */
  void SetTenkanSen(unsigned int _tenkan_sen) {
    istate.is_changed = true;
    params.tenkan_sen = _tenkan_sen;
  }

  /**
   * Set period of Kijun-sen line.
   */
  void SetKijunSen(unsigned int _kijun_sen) {
    istate.is_changed = true;
    params.kijun_sen = _kijun_sen;
  }

  /**
   * Set period of Senkou Span B line.
   */
  void SetSenkouSpanB(unsigned int _senkou_span_b) {
    istate.is_changed = true;
    params.senkou_span_b = _senkou_span_b;
  }
};
