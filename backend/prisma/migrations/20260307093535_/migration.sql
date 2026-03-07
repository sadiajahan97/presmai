/*
  Warnings:

  - You are about to drop the column `image` on the `messages` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "messages" DROP COLUMN "image",
ADD COLUMN     "file_path" TEXT;
