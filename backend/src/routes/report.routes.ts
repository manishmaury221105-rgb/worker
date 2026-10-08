import { Router } from 'express';
import { getDashboardSummary } from '../controllers/report.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/dashboard', requireRole('ADMIN'), getDashboardSummary);

export default router;
