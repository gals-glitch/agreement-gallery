import { Router } from "express";
import { investorController } from "../controllers/investorController";

const router = Router();

router.get("/search", (req, res, next) => investorController.search(req, res, next));
router.get("/:contactId/portfolio", (req, res, next) => investorController.portfolio(req, res, next));

export default router;

