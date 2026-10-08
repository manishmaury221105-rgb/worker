import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const getDashboardSummary = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const now = new Date();
    const today = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
    const m = now.getMonth();
    const y = now.getFullYear();
    const startOfMonth = new Date(Date.UTC(y, m, 1));
    const endOfMonth = new Date(Date.UTC(y, m + 1, 0, 23, 59, 59));

    const [
      totalWorkers,
      activeWorkers,
      todayAttendances,
      pendingLeaves,
      pendingAdvances,
      pendingExpenses,
      taskStats,
      monthlyAttendances,
      departmentsCount,
    ] = await Promise.all([
      prisma.user.count({ where: { role: 'WORKER' } }),
      prisma.user.count({ where: { role: 'WORKER', status: 'ACTIVE' } }),
      prisma.attendance.findMany({
        where: { date: today },
        include: { user: { select: { name: true, department: true } } },
      }),
      prisma.leaveRequest.count({ where: { status: 'PENDING' } }),
      prisma.salaryAdvance.count({ where: { status: 'PENDING' } }),
      prisma.expense.count({ where: { status: 'PENDING' } }),
      prisma.task.groupBy({
        by: ['status'],
        _count: { id: true },
      }),
      prisma.attendance.findMany({
        where: { date: { gte: startOfMonth, lte: endOfMonth } },
        select: { status: true, date: true, workingHours: true },
      }),
      prisma.user.groupBy({
        by: ['department'],
        where: { role: 'WORKER' },
        _count: { id: true },
      }),
    ]);

    let presentToday = 0;
    let lateToday = 0;
    let halfDayToday = 0;
    let onLeaveToday = 0;

    todayAttendances.forEach((a) => {
      if (a.status === 'PRESENT') presentToday++;
      if (a.status === 'LATE') { lateToday++; presentToday++; }
      if (a.status === 'HALF_DAY') halfDayToday++;
      if (a.status === 'ON_LEAVE') onLeaveToday++;
    });

    const absentToday = Math.max(0, activeWorkers - presentToday - onLeaveToday - halfDayToday);

    // Group tasks
    const tasksMap: Record<string, number> = {
      PENDING: 0,
      IN_PROGRESS: 0,
      COMPLETED: 0,
      CANCELLED: 0,
    };
    taskStats.forEach((t) => {
      tasksMap[t.status] = t._count.id;
    });

    // Monthly attendance overview
    let monthlyPresent = 0;
    let monthlyTotalHours = 0;
    monthlyAttendances.forEach((a) => {
      if (a.status === 'PRESENT' || a.status === 'LATE') monthlyPresent++;
      monthlyTotalHours += a.workingHours || 0;
    });

    res.status(200).json({
      success: true,
      data: {
        workers: {
          total: totalWorkers,
          active: activeWorkers,
          inactive: totalWorkers - activeWorkers,
          departments: departmentsCount.map((d) => ({
            name: d.department,
            count: d._count.id,
          })),
        },
        attendanceToday: {
          present: presentToday,
          late: lateToday,
          halfDay: halfDayToday,
          absent: absentToday,
          onLeave: onLeaveToday,
          attendanceRate: activeWorkers > 0 ? Math.round((presentToday / activeWorkers) * 100) : 0,
        },
        pendingApprovals: {
          leaves: pendingLeaves,
          advances: pendingAdvances,
          expenses: pendingExpenses,
          total: pendingLeaves + pendingAdvances + pendingExpenses,
        },
        tasks: {
          pending: tasksMap.PENDING,
          inProgress: tasksMap.IN_PROGRESS,
          completed: tasksMap.COMPLETED,
          total: tasksMap.PENDING + tasksMap.IN_PROGRESS + tasksMap.COMPLETED + tasksMap.CANCELLED,
          completionRate:
            tasksMap.PENDING + tasksMap.IN_PROGRESS + tasksMap.COMPLETED > 0
              ? Math.round(
                  (tasksMap.COMPLETED / (tasksMap.PENDING + tasksMap.IN_PROGRESS + tasksMap.COMPLETED)) * 100
                )
              : 0,
        },
        monthlyMetrics: {
          month: m + 1,
          year: y,
          totalLogs: monthlyAttendances.length,
          totalWorkingHours: Math.round(monthlyTotalHours * 10) / 10,
        },
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate dashboard report',
    });
  }
};
