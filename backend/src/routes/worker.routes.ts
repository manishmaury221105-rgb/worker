import { Router } from 'express';
import {
  getAllWorkers,
  getWorkerById,
  createWorker,
  updateWorker,
  deleteWorker,
  getDepartments,
} from '../controllers/worker.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/departments', getDepartments);
router.get('/', requireRole('ADMIN'), getAllWorkers);
router.get('/:id', getWorkerById);
router.post('/', requireRole('ADMIN'), createWorker);
router.put('/:id', requireRole('ADMIN'), updateWorker);
router.delete('/:id', requireRole('ADMIN'), deleteWorker);

export default router;
