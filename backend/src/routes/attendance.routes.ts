import { Router } from 'express';
import {
  checkIn,
  checkOut,
  selfMarkAttendance,
  getTodayAttendance,
  getMyAttendanceHistory,
  getAllAttendance,
  manualMarkAttendance,
  getAttendanceSummary,
  getAttendanceLockStatus,
  toggleAttendanceLock,
  getWorkerMonthlyAttendance,
} from '../controllers/attendance.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/check-in', checkIn);
router.post('/check-out', checkOut);
router.post('/self-mark', selfMarkAttendance);
router.get('/today', getTodayAttendance);
router.get('/my-history', getMyAttendanceHistory);
router.get('/lock-status', getAttendanceLockStatus);
router.get('/worker-monthly', requireRole('ADMIN'), getWorkerMonthlyAttendance);
router.post('/toggle-lock', requireRole('ADMIN'), toggleAttendanceLock);
router.get('/summary', requireRole('ADMIN'), getAttendanceSummary);
router.get('/all', requireRole('ADMIN'), getAllAttendance);
router.post('/manual', requireRole('ADMIN'), manualMarkAttendance);

export default router;

