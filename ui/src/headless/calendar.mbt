///|
/// Gregorian date algorithms adapted from RUI calendar.mbt at b1291945.
/// MIT; see the module THIRD_PARTY_NOTICES.md.
pub struct CalendarDate {
  year : Int
  month : Int
  day : Int
} derive(Eq, Debug)

///|
pub fn days_in_month(year : Int, month : Int) -> Int {
  match month {
    2 =>
      if year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) {
        29
      } else {
        28
      }
    4 | 6 | 9 | 11 => 30
    _ => 31
  }
}

///|
pub fn calendar_date(year~ : Int, month~ : Int, day~ : Int) -> CalendarDate {
  let year = year.clamp(min=1, max=9999)
  let month = month.clamp(min=1, max=12)
  { year, month, day: day.clamp(min=1, max=days_in_month(year, month)), }
}

///|
pub fn CalendarDate::ordinal(self : CalendarDate) -> Int {
  let year = self.year - 1
  let mut days = 365 * year + year / 4 - year / 100 + year / 400 + self.day
  for month = 1; month < self.month; month = month + 1 {
    days = days + days_in_month(self.year, month)
  }
  days
}

///|
pub fn CalendarDate::weekday(self : CalendarDate) -> Int {
  self.ordinal() % 7
}

///|
pub fn CalendarDate::add_months(
  self : CalendarDate,
  delta : Int,
) -> CalendarDate {
  let index = ((self.year - 1) * 12 + self.month - 1 + delta).clamp(
    min=0,
    max=119987,
  )
  calendar_date(year=index / 12 + 1, month=index % 12 + 1, day=self.day)
}

///|
pub fn CalendarDate::add_days(self : CalendarDate, delta : Int) -> CalendarDate {
  let target = (self.ordinal() + delta).clamp(min=1, max=3652059)
  let mut low = 1
  let mut high = 9999
  while low < high {
    let middle = (low + high + 1) / 2
    if calendar_date(year=middle, month=1, day=1).ordinal() <= target {
      low = middle
    } else {
      high = middle - 1
    }
  }
  let mut remaining = target -
    calendar_date(year=low, month=1, day=1).ordinal() +
    1
  let mut month = 1
  while remaining > days_in_month(low, month) {
    remaining = remaining - days_in_month(low, month)
    month = month + 1
  }
  calendar_date(year=low, month~, day=remaining)
}

///|
pub fn CalendarDate::iso(self : CalendarDate) -> String {
  let y = self.year.to_string()
  let m = self.month.to_string()
  let d = self.day.to_string()
  "0".repeat(4 - y.length()) +
  y +
  "-" +
  "0".repeat(2 - m.length()) +
  m +
  "-" +
  "0".repeat(2 - d.length()) +
  d
}

///|
pub(all) enum DateSelection {
  Single(CalendarDate?)
  Multiple(Array[CalendarDate])
  Range(CalendarDate?, CalendarDate?)
} derive(Eq, Debug)

///|
pub fn DateSelection::choose(
  self : DateSelection,
  date : CalendarDate,
) -> DateSelection {
  match self {
    Single(_) => Single(Some(date))
    Multiple(values) =>
      if values.contains(date) {
        Multiple(values.filter(value => value != date))
      } else {
        let next = values.copy()
        next.push(date)
        Multiple(next)
      }
    Range(Some(start), None) =>
      if date.ordinal() < start.ordinal() {
        Range(Some(date), Some(start))
      } else {
        Range(Some(start), Some(date))
      }
    Range(_, _) => Range(Some(date), None)
  }
}

///|
pub fn DateSelection::contains(
  self : DateSelection,
  date : CalendarDate,
) -> Bool {
  match self {
    Single(value) => value == Some(date)
    Multiple(values) => values.contains(date)
    Range(Some(start), Some(end)) =>
      date.ordinal() >= start.ordinal() && date.ordinal() <= end.ordinal()
    Range(start, _) => start == Some(date)
  }
}
