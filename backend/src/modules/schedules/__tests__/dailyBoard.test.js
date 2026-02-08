// backend/src/modules/schedules/__tests__/dailyBoard.test.js

jest.mock('../schedules.repo', () => ({
  schedulesRepo: {
    listDoctorsBasic: jest.fn(),
    getOverrideByDate: jest.fn(),
    getWeeklyByWeekday: jest.fn(),
  }
}));

jest.mock('../../appointments/appointments.repo', () => ({
  appointmentsRepo: {
    listForBoardByDate: jest.fn(),
  }
}));

const { schedulesRepo } = require('../schedules.repo');
const { appointmentsRepo } = require('../../appointments/appointments.repo');
const { schedulesService } = require('../schedules.service');

describe('schedulesService.dailyBoard', () => {
  test('returns BOOKED slot with patientName', async () => {
    // Arrange
    schedulesRepo.listDoctorsBasic.mockResolvedValue([
      { id: 5, full_name: 'Dr A' },
    ]);

    schedulesRepo.getOverrideByDate.mockResolvedValue(null);

    schedulesRepo.getWeeklyByWeekday.mockResolvedValue([
      { start_time: '09:00:00', end_time: '10:00:00', slot_minutes: 30 },
    ]);

    appointmentsRepo.listForBoardByDate.mockResolvedValue([
      {
        id: 12,
        doctor_id: 5,
        patient_id: 6,
        patient_name: 'Patient A',
        status: 'BOOKED',
        start_at: '2026-01-29 09:30:00',
      }
    ]);

    // Act
    const out = await schedulesService.dailyBoard('2026-01-29');

    // Assert
    expect(out.date).toBe('2026-01-29');
    expect(out.doctors).toHaveLength(1);

    const d = out.doctors[0];
    const s0900 = d.slots.find(x => x.time === '09:00');
    const s0930 = d.slots.find(x => x.time === '09:30');

    expect(s0900.status).toBe('AVAILABLE');

    expect(s0930.status).toBe('BOOKED');
    expect(s0930.patientName).toBe('Patient A');
    expect(s0930.appointmentId).toBe(12);
  });
});
