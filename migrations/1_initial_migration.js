const Migrations = artifacts.require("Migrations");
const EscrowPayments = artifacts.require("EscrowPayments");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(EscrowPayments);
};
