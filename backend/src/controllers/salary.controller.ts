import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const getMySalaryRecords = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const records = await prisma.salaryRecord.findMany({
      where: { userId: req.user.id },
      orderBy: [{ year: 'desc' }, { month: 'desc' }],
    });

    res.status(200).json({
      success: true,
      data: records,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch salary records',
    });
  }
};

export const getAllSalaryRecords = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { month, year, status, workerId } = req.query;

    const where: any = {};

    if (month) where.month = Number(month);
    if (year) where.year = Number(year);
    if (status && status !== 'ALL') where.status = String(status);
    if (workerId) where.userId = String(workerId);

    const records = await prisma.salaryRecord.findMany({
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
            bankAccount: true,
            upiId: true,
          },
        },
      },
      orderBy: [{ year: 'desc' }, { month: 'desc' }, { createdAt: 'desc' }],
    });

    res.status(200).json({
      success: true,
      count: records.length,
      data: records,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch salary records',
    });
  }
};

export const generatePayslip = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { userId, month, year, presentDays: manualPresentDays, bonus = 0, deductions = 0, notes } = req.body;

    if (!userId || !month || !year) {
      res.status(400).json({
        success: false,
        message: 'Worker ID, month and year are required',
      });
      return;
    }

    const worker = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!worker) {
      res.status(404).json({ success: false, message: 'Worker not found' });
      return;
    }

    let presentDays: number;
    let halfDays = 0;
    let totalWorkingHours = 0;

    if (manualPresentDays !== undefined && manualPresentDays !== null && manualPresentDays !== '') {
      presentDays = Number(manualPresentDays);
      totalWorkingHours = presentDays * 8;
    } else {
      // Calculate attendance in that month from database
      const m = Number(month) - 1;
      const y = Number(year);
      const startOfMonth = new Date(Date.UTC(y, m, 1));
      const endOfMonth = new Date(Date.UTC(y, m + 1, 0, 23, 59, 59));

      const attendances = await prisma.attendance.findMany({
        where: {
          userId,
          date: { gte: startOfMonth, lte: endOfMonth },
        },
      });

      presentDays = attendances.filter((a) => a.status === 'PRESENT' || a.status === 'LATE').length;
      halfDays = attendances.filter((a) => a.status === 'HALF_DAY').length;
      totalWorkingHours = attendances.reduce((acc, curr) => acc + (curr.workingHours || 0), 0);
    }

    const dailySalary = worker.monthlySalary;
    // Formula: Daily Salary * Present Days (effective days with half days)
    const effectiveDays = presentDays + (halfDays * 0.5);
    const calculatedPay = Math.round((dailySalary * effectiveDays + Number(bonus) - Number(deductions)) * 100) / 100;
    const netSalary = Math.max(0, calculatedPay);

    const salaryRecord = await prisma.salaryRecord.upsert({
      where: {
        userId_month_year: {
          userId,
          month: Number(month),
          year: Number(year),
        },
      },
      update: {
        baseSalary: dailySalary,
        allowance: Number(bonus),
        deductions: Number(deductions),
        netSalary,
        presentDays: effectiveDays,
        absentDays: Math.max(0, 30 - Math.round(effectiveDays)),
        totalWorkingHours: Math.round(totalWorkingHours * 10) / 10,
        notes,
      },
      create: {
        userId,
        month: Number(month),
        year: Number(year),
        baseSalary: dailySalary,
        allowance: Number(bonus),
        deductions: Number(deductions),
        netSalary,
        presentDays: effectiveDays,
        absentDays: Math.max(0, 30 - Math.round(effectiveDays)),
        totalWorkingHours: Math.round(totalWorkingHours * 10) / 10,
        status: 'PENDING',
        notes,
      },
    });

    res.status(200).json({
      success: true,
      message: 'Payslip generated successfully',
      data: salaryRecord,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate payslip',
    });
  }
};

export const updateSalaryStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { status, paymentMethod = 'Bank Transfer', notes } = req.body;

    const record = await prisma.salaryRecord.update({
      where: { id: id as string },
      data: {
        status,
        paymentDate: status === 'PAID' ? new Date() : null,
        paymentMethod: status === 'PAID' ? paymentMethod : null,
        ...(notes && { notes }),
      },
      include: {
        user: { select: { id: true, name: true } },
      },
    });

    if (status === 'PAID') {
      await prisma.notification.create({
        data: {
          userId: record.userId,
          title: 'Salary Credited',
          message: `Your salary of ₹${record.netSalary} for month ${record.month}/${record.year} has been processed via ${paymentMethod}.`,
          type: 'SALARY',
        },
      });
    }

    res.status(200).json({
      success: true,
      message: `Salary marked as ${status}`,
      data: record,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update salary status',
    });
  }
};

// Advances
export const requestAdvance = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { amount, reason } = req.body;

    if (!amount || !reason) {
      res.status(400).json({
        success: false,
        message: 'Amount and reason are required',
      });
      return;
    }

    const advance = await prisma.salaryAdvance.create({
      data: {
        userId: req.user.id,
        amount: Number(amount),
        reason: reason.trim(),
        status: 'PENDING',
      },
    });

    res.status(201).json({
      success: true,
      message: 'Advance salary request submitted',
      data: advance,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to request advance',
    });
  }
};

export const getMyAdvances = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const advances = await prisma.salaryAdvance.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json({
      success: true,
      data: advances,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch advances',
    });
  }
};

export const getAllAdvances = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { status } = req.query;

    const where: any = {};
    if (status && status !== 'ALL') {
      where.status = String(status);
    }

    const advances = await prisma.salaryAdvance.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
            department: true,
            designation: true,
            monthlySalary: true,
          },
        },
      },
      orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
    });

    res.status(200).json({
      success: true,
      count: advances.length,
      data: advances,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch advances',
    });
  }
};

export const reviewAdvance = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { id } = req.params;
    const { status, adminComment } = req.body;

    const advance = await prisma.salaryAdvance.update({
      where: { id: id as string },
      data: {
        status,
        adminComment,
        approvedById: req.user.id,
        payoutDate: status === 'APPROVED' ? new Date() : null,
      },
    });

    // Notify worker
    await prisma.notification.create({
      data: {
        userId: advance.userId,
        title: `Salary Advance ${status}`,
        message: `Your advance request of ₹${advance.amount} was ${status.toLowerCase()}.${adminComment ? ` Note: ${adminComment}` : ''}`,
        type: 'SALARY',
      },
    });

    res.status(200).json({
      success: true,
      message: `Advance request ${status.toLowerCase()}`,
      data: advance,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to review advance request',
    });
  }
};
