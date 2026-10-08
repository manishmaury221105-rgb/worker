import { Router } from 'express';
import {
  getMySalaryRecords,
  getAllSalaryRecords,
  generatePayslip,
  updateSalaryStatus,
  requestAdvance,
  getMyAdvances,
  getAllAdvances,
  reviewAdvance,
} from '../controllers/salary.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Payslips & Salary
router.get('/my-records', getMySalaryRecords);
router.get('/all-records', requireRole('ADMIN'), getAllSalaryRecords);
router.post('/generate-payslip', requireRole('ADMIN'), generatePayslip);
router.patch('/records/:id/status', requireRole('ADMIN'), updateSalaryStatus);

// Advances
router.post('/advance/request', requestAdvance);
router.get('/advance/my', getMyAdvances);
router.get('/advance/all', requireRole('ADMIN'), getAllAdvances);
router.patch('/advance/:id/review', requireRole('ADMIN'), reviewAdvance);

export default router;
