import { Router } from 'express';
import {
  applyLeave,
  getMyLeaves,
  getAllLeaves,
  reviewLeave,
} from '../controllers/leave.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/apply', applyLeave);
router.get('/my-leaves', getMyLeaves);
router.get('/all', requireRole('ADMIN'), getAllLeaves);
router.patch('/:id/review', requireRole('ADMIN'), reviewLeave);
router.patch('/all/:id/review', requireRole('ADMIN'), reviewLeave);

export default router;
