-- CreateTable
CREATE TABLE "medications" (
    "id" TEXT NOT NULL,
    "afternoon" BOOLEAN NOT NULL,
    "days" INTEGER NOT NULL,
    "morning" BOOLEAN NOT NULL,
    "name" TEXT NOT NULL,
    "night" BOOLEAN NOT NULL,
    "strength" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "medications_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "medications" ADD CONSTRAINT "medications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
