import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const applyLeave = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { leaveType = 'CASUAL', startDate, endDate, reason } = req.body;

    if (!startDate || !endDate || !reason) {
      res.status(400).json({
        success: false,
        message: 'Start date, end date and reason are required',
      });
      return;
    }

    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffTime = Math.abs(end.getTime() - start.getTime());
    const totalDays = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1);

    const leave = await prisma.leaveRequest.create({
      data: {
        userId: req.user.id,
        leaveType,
        startDate: start,
        endDate: end,
        totalDays,
        reason: reason.trim(),
        status: 'PENDING',
      },
    });

    res.status(201).json({
      success: true,
      message: 'Leave application submitted successfully',
      data: leave,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to submit leave application',
    });
  }
};

export const getMyLeaves = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const leaves = await prisma.leaveRequest.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json({
      success: true,
      data: leaves,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch leaves',
    });
  }
};

export const getAllLeaves = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { status, workerId } = req.query;

    const where: any = {};

    if (status && status !== 'ALL') {
      where.status = String(status);
    }

    if (workerId) {
      where.userId = String(workerId);
    }

    const leaves = await prisma.leaveRequest.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            department: true,
            designation: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
    });

    res.status(200).json({
      success: true,
      count: leaves.length,
      data: leaves,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch leave requests',
    });
  }
};

export const reviewLeave = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { id } = req.params;
    const { status, adminComment } = req.body;

    if (!status || !['APPROVED', 'REJECTED'].includes(status)) {
      res.status(400).json({
        success: false,
        message: 'Valid status (APPROVED or REJECTED) is required',
      });
      return;
    }

    const leave = await prisma.leaveRequest.update({
      where: { id: id as string },
      data: {
        status,
        adminComment,
        approvedById: req.user.id,
      },
      include: {
        user: { select: { name: true } },
      },
    });

    // Notify worker
    await prisma.notification.create({
      data: {
        userId: leave.userId,
        title: `Leave Request ${status}`,
        message: `Your leave request for ${leave.totalDays} day(s) was ${status.toLowerCase()}.${adminComment ? ` Remark: ${adminComment}` : ''}`,
        type: 'LEAVE',
      },
    });

    res.status(200).json({
      success: true,
      message: `Leave request has been ${status.toLowerCase()}`,
      data: leave,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to review leave request',
    });
  }
};
