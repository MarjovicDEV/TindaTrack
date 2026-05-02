/// Primary shell sections for [NavigationRail] and bottom bar slots
/// (excluding the center FAB).
enum ShellDestination {
  home(0),
  stock(1),
  history(2),
  reports(3);

  const ShellDestination(this.railIndex);
  final int railIndex;
}
