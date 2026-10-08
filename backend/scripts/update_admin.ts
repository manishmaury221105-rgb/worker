import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const salt = await bcrypt.genSalt(10);
  const adminPassword = await bcrypt.hash('Aj@y', salt);

  // Check if admin with phone 9695718820 or role ADMIN exists
  const existingAdmin = await prisma.user.findFirst({
    where: {
      OR: [
        { phone: '9695718820' },
        { phone: '9876543210' },
        { email: 'admin@workerapp.com' },
        { role: 'ADMIN' },
      ],
    },
  });

  if (existingAdmin) {
    const updated = await prisma.user.update({
      where: { id: existingAdmin.id },
      data: {
        name: 'अजय मौर्य (Admin)',
        phone: '9695718820',
        email: 'ajay@laxminarayan.com',
        password: adminPassword,
        role: 'ADMIN',
        department: 'Management',
        designation: 'Owner / Director',
        address: 'घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर',
      },
    });
    console.log(`✅ Admin updated successfully: ID/Phone=${updated.phone}, Name=${updated.name}`);
  } else {
    const created = await prisma.user.create({
      data: {
        name: 'अजय मौर्य (Admin)',
        phone: '9695718820',
        email: 'ajay@laxminarayan.com',
        password: adminPassword,
        role: 'ADMIN',
        department: 'Management',
        designation: 'Owner / Director',
        monthlySalary: 75000,
        hourlyRate: 400,
        status: 'ACTIVE',
        address: 'घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर',
      },
    });
    console.log(`✅ Admin created successfully: ID/Phone=${created.phone}, Name=${created.name}`);
  }
}

main()
  .catch((e) => {
    console.error('Error updating admin:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
