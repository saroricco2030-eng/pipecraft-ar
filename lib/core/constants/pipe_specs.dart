class PipeSpec {
  final int od;
  final double minRadius;

  const PipeSpec({required this.od, required this.minRadius});
}

enum Machine {
  robend4000('ROBEND 4000'),
  remsCurvo('REMS Curvo');

  final String label;
  const Machine(this.label);
}

const Map<int, PipeSpec> pipeSpecs = {
  15: PipeSpec(od: 15, minRadius: 45),
  19: PipeSpec(od: 19, minRadius: 57),
  22: PipeSpec(od: 22, minRadius: 66),
  25: PipeSpec(od: 25, minRadius: 75),
  28: PipeSpec(od: 28, minRadius: 84),
  35: PipeSpec(od: 35, minRadius: 105),
};

const Map<Machine, Map<int, double>> springBack = {
  Machine.robend4000: {
    15: 2,
    19: 2,
    22: 3,
    25: 3,
    28: 3,
    35: 4,
  },
  Machine.remsCurvo: {
    15: 2,
    19: 2,
    22: 2,
    25: 3,
    28: 3,
    35: 4,
  },
};
