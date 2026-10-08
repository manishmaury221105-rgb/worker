import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const submitExpense = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { category = 'OTHER', amount, description, receiptUrl, expenseDate } = req.body;

    if (!amount || !description) {
      res.status(400).json({
        success: false,
        message: 'Amount and description are required',
      });
      return;
    }

    const expense = await prisma.expense.create({
      data: {
        userId: req.user.id,
        category,
        amount: Number(amount),
        description: description.trim(),
        receiptUrl,
        expenseDate: expenseDate ? new Date(expenseDate) : new Date(),
        status: 'PENDING',
      },
    });

    res.status(201).json({
      success: true,
      message: 'Expense submitted successfully',
      data: expense,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to submit expense',
    });
  }
};

export const getMyExpenses = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const expenses = await prisma.expense.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    });

    const totalAmount = expenses.reduce((acc, curr) => acc + curr.amount, 0);

    res.status(200).json({
      success: true,
      totalAmount,
      data: expenses,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch expenses',
    });
  }
};

export const getAllExpenses = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { status, category, workerId } = req.query;

    const where: any = {};

    if (status && status !== 'ALL') where.status = String(status);
    if (category && category !== 'ALL') where.category = String(category);
    if (workerId) where.userId = String(workerId);

    const expenses = await prisma.expense.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
            department: true,
            designation: true,
          },
        },
      },
      orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
    });

    const totalAmount = expenses.reduce((acc, curr) => acc + curr.amount, 0);

    res.status(200).json({
      success: true,
      count: expenses.length,
      totalAmount,
      data: expenses,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch expenses',
    });
  }
};

export const reviewExpense = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { status, adminComment } = req.body;

    if (!status || !['APPROVED', 'REJECTED', 'REIMBURSED'].includes(status)) {
      res.status(400).json({
        success: false,
        message: 'Valid status (APPROVED, REJECTED, REIMBURSED) is required',
      });
      return;
    }

    const expense = await prisma.expense.update({
      where: { id: id as string },
      data: {
        status,
        ...(adminComment !== undefined && { adminComment }),
      },
    });

    // Notify worker
    await prisma.notification.create({
      data: {
        userId: expense.userId,
        title: `Expense Claim ${status}`,
        message: `Your expense claim of ₹${expense.amount} (${expense.category}) was ${status.toLowerCase()}.${adminComment ? ` Note: ${adminComment}` : ''}`,
        type: 'EXPENSE',
      },
    });

    res.status(200).json({
      success: true,
      message: `Expense claim ${status.toLowerCase()}`,
      data: expense,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to review expense',
    });
  }
};
