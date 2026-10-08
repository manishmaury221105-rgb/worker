import { Router } from 'express';
import {
  submitExpense,
  getMyExpenses,
  getAllExpenses,
  reviewExpense,
} from '../controllers/expense.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/submit', submitExpense);
router.get('/my', getMyExpenses);
router.get('/all', requireRole('ADMIN'), getAllExpenses);
router.patch('/:id/review', requireRole('ADMIN'), reviewExpense);

export default router;
