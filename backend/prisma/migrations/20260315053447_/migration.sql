-- CreateTable
CREATE TABLE "medicines" (
    "id" TEXT NOT NULL,
    "company" TEXT,
    "ingredient" TEXT,
    "link" TEXT,
    "major_points" TEXT,
    "name" TEXT,
    "price" DOUBLE PRECISION,
    "strength" TEXT,
    "type" TEXT,
    "unit" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "medicines_pkey" PRIMARY KEY ("id")
);
